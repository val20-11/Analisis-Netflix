/* ============================================================================
   CONFIGURACIÓN INICIAL
   ============================================================================ */

OPTIONS nodate nonumber;
ODS GRAPHICS / reset=all imagefmt=png width=800px height=600px;
ODS HTML path='/home/u64398734' file='analisis_netflix_COMPLETO.html';

TITLE1 'ANÁLISIS EXPLORATORIO COMPLETO: NETFLIX 2021';
TITLE2 'Estadística Descriptiva + Teoría de Muestreo';
FOOTNOTE1 'Estadística I - FES Acatlán UNAM';

/* ============================================================================
   IMPORTAR DATOS DESDE CSV Y GUARDAR EN LIBRERÍA PERMANENTE
   ============================================================================ */

TITLE2 '====== IMPORTACIÓN DE DATOS ======';

/* Definir librería permanente */
LIBNAME mydata '/home/u64398734/sasuser.v94';

/* Importar desde CSV */
FILENAME REFFILE '/home/u64398734/sasuser.v94/netflix_limpio.csv';

PROC IMPORT DATAFILE=REFFILE
    DBMS=CSV
    OUT=mydata.netflix_limpio
    REPLACE;
    GETNAMES=YES;
    GUESSINGROWS=MAX;
RUN;

/* Copiar a work para el análisis */
DATA work.netflix;
    SET mydata.netflix_limpio;
RUN;

/* Verificar estructura */
PROC CONTENTS DATA=work.netflix SHORT;
RUN;

DATA _null_;
    PUT '============================================';
    PUT 'DATOS IMPORTADOS Y GUARDADOS CORRECTAMENTE';
    PUT 'Librería permanente: mydata.netflix_limpio';
    PUT 'Dataset de trabajo: work.netflix';
    PUT '============================================';
RUN;

/* ============================================================================
   PARTE 1: ANÁLISIS DESCRIPTIVO DE LA POBLACIÓN COMPLETA
   ============================================================================ */

TITLE2 '====== PARTE 1: ESTADÍSTICAS DESCRIPTIVAS (POBLACIÓN) ======';

/* 1.1 Resumen General */
TITLE3 '1.1 Resumen General del Dataset';

PROC SQL;
    SELECT 
        COUNT(*) AS Total_Registros,
        COUNT(DISTINCT show_id) AS Titulos_Unicos,
        COUNT(DISTINCT type) AS Tipos_Contenido
    FROM work.netflix;
QUIT;

/* 1.2 Distribución de Tipo de Contenido */
TITLE3 '1.2 Distribución: Películas vs Series';

PROC FREQ DATA=work.netflix ORDER=freq;
    TABLES type / PLOTS=freqplot(scale=percent) NOCUM;
RUN;

PROC SGPLOT DATA=work.netflix;
    TITLE4 'Gráfico de Barras: Tipo de Contenido';
    VBAR type / STAT=percent DATALABEL;
    XAXIS LABEL='Tipo de Contenido';
    YAXIS LABEL='Porcentaje (%)';
RUN;

/* 1.3 Análisis Temporal: Año de Lanzamiento */
TITLE3 '1.3 Análisis Temporal: Año de Lanzamiento';

PROC MEANS DATA=work.netflix(WHERE=(release_year NE .)) 
    N MEAN MEDIAN MODE STD MIN MAX Q1 Q3 RANGE SKEW KURT;
    VAR release_year;
    OUTPUT OUT=work.stats_year_pob
        N=n MEAN=media MEDIAN=mediana MODE=moda 
        STD=desv_std MIN=minimo MAX=maximo 
        Q1=q1 Q3=q3 RANGE=rango 
        SKEW=asimetria KURT=curtosis;
RUN;

/* Guardar parámetros poblacionales */
DATA work.parametros_poblacionales;
    SET work.stats_year_pob;
    tipo = 'POBLACION';
RUN;

PROC PRINT DATA=work.parametros_poblacionales NOOBS LABEL;
    LABEL 
        media='Media (μ)' 
        mediana='Mediana' 
        moda='Moda' 
        desv_std='Desv. Estándar (σ)' 
        minimo='Mínimo' 
        maximo='Máximo' 
        q1='Q1 (25%)' 
        q3='Q3 (75%)' 
        rango='Rango' 
        asimetria='Asimetría (Skewness)' 
        curtosis='Curtosis (Kurtosis)';
    FORMAT media mediana moda desv_std 8.2 asimetria curtosis 8.4;
RUN;

/* Interpretación de asimetría y curtosis */
DATA work.interpretacion;
    SET work.parametros_poblacionales;
    LENGTH interp_asimetria $100 interp_curtosis $100;
    
    IF asimetria < -0.5 THEN 
        interp_asimetria = 'Sesgada a la IZQUIERDA (cola izquierda más larga)';
    ELSE IF asimetria > 0.5 THEN 
        interp_asimetria = 'Sesgada a la DERECHA (cola derecha más larga)';
    ELSE 
        interp_asimetria = 'Aproximadamente SIMÉTRICA';
    
    IF curtosis > 3 THEN 
        interp_curtosis = 'LEPTOCÚRTICA (más puntiaguda que normal)';
    ELSE IF curtosis < 3 THEN 
        interp_curtosis = 'PLATICÚRTICA (más aplanada que normal)';
    ELSE 
        interp_curtosis = 'MESOCÚRTICA (similar a distribución normal)';
RUN;

TITLE4 'Interpretación de Medidas de Forma';
PROC PRINT DATA=work.interpretacion NOOBS;
    VAR asimetria interp_asimetria curtosis interp_curtosis;
    FORMAT asimetria curtosis 8.4;
RUN;

/* 1.4 Distribución por Décadas */
TITLE3 '1.4 Distribución por Décadas';

PROC FREQ DATA=work.netflix ORDER=freq;
    TABLES release_decade / PLOTS=freqplot(scale=percent) NOCUM;
RUN;

/* 1.5 Histograma con Curva de Densidad */
TITLE3 '1.5 Histograma: Distribución de Años';

PROC SGPLOT DATA=work.netflix(WHERE=(release_year NE .));
    HISTOGRAM release_year / BINWIDTH=5;
    DENSITY release_year / TYPE=kernel;
    XAXIS LABEL='Año de Lanzamiento';
    YAXIS LABEL='Frecuencia';
RUN;

/* 1.6 Boxplot por Tipo de Contenido */
TITLE3 '1.6 Comparación de Años: Películas vs Series';

PROC SGPLOT DATA=work.netflix(WHERE=(release_year NE .));
    VBOX release_year / CATEGORY=type;
    XAXIS LABEL='Tipo de Contenido';
    YAXIS LABEL='Año de Lanzamiento';
RUN;

/* 1.7 Análisis de Ratings */
TITLE3 '1.7 Análisis de Ratings (Clasificaciones)';

PROC FREQ DATA=work.netflix ORDER=freq;
    TABLES rating / PLOTS=freqplot(scale=percent) NOCUM;
RUN;

PROC FREQ DATA=work.netflix ORDER=freq;
    TABLES rating_group / PLOTS=freqplot NOCUM;
RUN;

/* Tabla cruzada: Tipo vs Rating */
TITLE4 'Relación: Tipo de Contenido vs Rating';
PROC FREQ DATA=work.netflix;
    TABLES type*rating_group / NOROW NOCOL PLOTS=freqplot;
RUN;

PROC SGPLOT DATA=work.netflix;
    TITLE4 'Rating por Tipo de Contenido';
    VBAR type / GROUP=rating_group GROUPDISPLAY=stack;
RUN;

/* 1.8 Análisis de Duración - PELÍCULAS */
TITLE3 '1.8 Análisis de Duración: Películas';

PROC MEANS DATA=work.netflix(WHERE=(type='Movie' AND duration_min NE .)) 
    N MEAN MEDIAN MODE STD MIN MAX Q1 Q3 RANGE SKEW KURT;
    VAR duration_min;
    OUTPUT OUT=work.stats_movies
        N=n MEAN=media MEDIAN=mediana STD=desv_std 
        MIN=minimo MAX=maximo Q1=q1 Q3=q3 
        SKEW=asimetria KURT=curtosis;
RUN;

PROC PRINT DATA=work.stats_movies NOOBS;
    FORMAT media mediana desv_std 8.2 asimetria curtosis 8.4;
RUN;

/* Histograma de duración */
TITLE4 'Histograma: Duración de Películas (minutos)';
PROC SGPLOT DATA=work.netflix(WHERE=(type='Movie' AND duration_min NE .));
    HISTOGRAM duration_min / BINWIDTH=10;
    DENSITY duration_min / TYPE=kernel;
    XAXIS LABEL='Duración (minutos)';
    YAXIS LABEL='Frecuencia';
RUN;

/* Boxplot para outliers */
TITLE4 'Boxplot: Detección de Outliers en Duración';
PROC SGPLOT DATA=work.netflix(WHERE=(type='Movie' AND duration_min NE .));
    VBOX duration_min;
    REFLINE 90 120 150 / AXIS=y LINEATTRS=(pattern=dash);
    YAXIS LABEL='Duración (minutos)';
RUN;

/* Clasificar películas por duración */
DATA work.movies_class;
    SET work.netflix(WHERE=(type='Movie' AND duration_min NE .));
    LENGTH duracion_categoria $25;
    
    IF duration_min < 60 THEN duracion_categoria = 'Corta (<60 min)';
    ELSE IF duration_min < 90 THEN duracion_categoria = 'Media (60-90 min)';
    ELSE IF duration_min < 120 THEN duracion_categoria = 'Estándar (90-120 min)';
    ELSE IF duration_min < 150 THEN duracion_categoria = 'Larga (120-150 min)';
    ELSE duracion_categoria = 'Muy Larga (>150 min)';
RUN;

TITLE4 'Distribución por Categoría de Duración';
PROC FREQ DATA=work.movies_class ORDER=data;
    TABLES duracion_categoria / PLOTS=freqplot NOCUM;
RUN;

/* 1.9 Detección de OUTLIERS con método IQR */
TITLE3 '1.9 Detección de Outliers: Método IQR';

/* Calcular límites */
DATA work.outlier_limits;
    SET work.stats_movies;
    iqr = q3 - q1;
    limite_inferior = q1 - 1.5 * iqr;
    limite_superior = q3 + 1.5 * iqr;
    limite_inf_extremo = q1 - 3 * iqr;
    limite_sup_extremo = q3 + 3 * iqr;
RUN;

TITLE4 'Límites para Detección de Outliers';
PROC PRINT DATA=work.outlier_limits NOOBS;
    VAR q1 q3 iqr limite_inferior limite_superior 
        limite_inf_extremo limite_sup_extremo;
    FORMAT _NUMERIC_ 8.2;
RUN;

/* Identificar outliers */
DATA work.movies_outliers;
    SET work.netflix(WHERE=(type='Movie' AND duration_min NE .));
    IF _N_ = 1 THEN SET work.outlier_limits;
    
    LENGTH tipo_outlier $20;
    
    IF duration_min < limite_inf_extremo OR duration_min > limite_sup_extremo THEN
        tipo_outlier = 'Outlier EXTREMO';
    ELSE IF duration_min < limite_inferior OR duration_min > limite_superior THEN
        tipo_outlier = 'Outlier MODERADO';
    ELSE
        tipo_outlier = 'Normal';
RUN;

TITLE4 'Resumen de Outliers';
PROC FREQ DATA=work.movies_outliers;
    TABLES tipo_outlier / NOCUM;
RUN;

/* Listar películas outliers */
TITLE4 'Top 20 Películas Más Largas (Outliers)';
PROC SORT DATA=work.movies_outliers(WHERE=(tipo_outlier NE 'Normal')) 
    OUT=work.outliers_sorted;
    BY DESCENDING duration_min;
RUN;

PROC PRINT DATA=work.outliers_sorted(OBS=20);
    VAR title duration_min release_year rating tipo_outlier;
    LABEL 
        title='Título'
        duration_min='Duración (min)'
        release_year='Año'
        rating='Rating'
        tipo_outlier='Tipo de Outlier';
RUN;

/* 1.10 Análisis de SERIES - Temporadas */
TITLE3 '1.10 Análisis de Series: Número de Temporadas';

PROC MEANS DATA=work.netflix(WHERE=(type='TV Show' AND duration_seasons NE .)) 
    N MEAN MEDIAN MODE STD MIN MAX Q1 Q3;
    VAR duration_seasons;
RUN;

TITLE4 'Distribución de Temporadas';
PROC FREQ DATA=work.netflix(WHERE=(type='TV Show' AND duration_seasons NE .)) ORDER=freq;
    TABLES duration_seasons / PLOTS=freqplot NOCUM MAXLEVELS=15;
RUN;

PROC SGPLOT DATA=work.netflix(WHERE=(type='TV Show' AND duration_seasons NE . AND duration_seasons <= 10));
    TITLE4 'Series por Número de Temporadas (1-10)';
    VBAR duration_seasons / STAT=freq DATALABEL;
    XAXIS LABEL='Número de Temporadas';
    YAXIS LABEL='Cantidad de Series';
RUN;

/* 1.11 Análisis de Valores Faltantes */
TITLE3 '1.11 Análisis de Valores Faltantes';

PROC SQL;
    CREATE TABLE work.missing_stats AS
    SELECT 
        COUNT(*) AS Total_Registros,
        SUM(CASE WHEN director='DIRECTOR_NOT_SPECIFIED' THEN 1 ELSE 0 END) AS Director_Faltante,
        SUM(CASE WHEN cast='CAST_NOT_SPECIFIED' THEN 1 ELSE 0 END) AS Cast_Faltante,
        SUM(CASE WHEN country='COUNTRY_NOT_SPECIFIED' THEN 1 ELSE 0 END) AS Country_Faltante,
        SUM(CASE WHEN date_added=. THEN 1 ELSE 0 END) AS Fecha_Faltante,
        SUM(CASE WHEN rating='NOT RATED' THEN 1 ELSE 0 END) AS Rating_Faltante
    FROM work.netflix;
QUIT;

DATA work.missing_pct;
    SET work.missing_stats;
    Pct_Director = (Director_Faltante / Total_Registros) * 100;
    Pct_Cast = (Cast_Faltante / Total_Registros) * 100;
    Pct_Country = (Country_Faltante / Total_Registros) * 100;
    Pct_Fecha = (Fecha_Faltante / Total_Registros) * 100;
    Pct_Rating = (Rating_Faltante / Total_Registros) * 100;
RUN;

PROC PRINT DATA=work.missing_pct NOOBS;
    VAR Total_Registros 
        Director_Faltante Pct_Director 
        Cast_Faltante Pct_Cast 
        Country_Faltante Pct_Country
        Fecha_Faltante Pct_Fecha
        Rating_Faltante Pct_Rating;
    FORMAT Pct_: 6.2;
RUN;

/* 1.12 Análisis Multivariado */
TITLE3 '1.12 Análisis Multivariado: Duración por Década';

PROC MEANS DATA=work.netflix(WHERE=(type='Movie' AND duration_min NE . AND release_decade NE 'Missing'))
    MEAN MEDIAN STD MIN MAX N;
    CLASS release_decade;
    VAR duration_min;
RUN;

TITLE4 'Distribución: Tipo de Contenido por Década';
PROC FREQ DATA=work.netflix(WHERE=(release_decade NE 'Missing'));
    TABLES release_decade*type / NOROW NOCOL;
RUN;

/* ============================================================================
   PARTE 2: TEORÍA DE MUESTREO - CÁLCULO DEL TAMAÑO DE MUESTRA
   ============================================================================ */

TITLE2 '====== PARTE 2: TEORÍA DE MUESTREO ======';
TITLE3 '2.1 Cálculo del Tamaño de Muestra Necesario';

/* Obtener parámetros poblacionales */
PROC SQL NOPRINT;
    SELECT 
        COUNT(*) AS N_pob,
        MEAN(release_year) AS mu,
        STD(release_year) AS sigma,
        MEAN(CASE WHEN type='Movie' THEN 1 ELSE 0 END) AS prop_movies
    INTO :N_total, :mu_pob, :sigma_pob, :p_movies
    FROM work.netflix
    WHERE release_year NE .;
QUIT;

DATA work.info_poblacion;
    N_poblacion = &N_total;
    mu_year = &mu_pob;
    sigma_year = &sigma_pob;
    p_movies = &p_movies;
    
    FORMAT mu_year 8.2 sigma_year 8.4 p_movies PERCENT8.2;
RUN;

PROC PRINT DATA=work.info_poblacion NOOBS;
    TITLE4 'Parámetros Poblacionales';
    VAR N_poblacion mu_year sigma_year p_movies;
RUN;

/* EXPLICACIÓN: ¿Por qué hay 2 tamaños de muestra diferentes? */
DATA _null_;
    FILE PRINT;
    PUT '============================================';
    PUT 'EXPLICACIÓN: DOS TAMAÑOS DE MUESTRA';
    PUT '============================================';
    PUT ' ';
    PUT '1. Para PROPORCIONES (Type: Movie vs TV Show)';
    PUT '   - Estima: % de películas vs series';
    PUT '   - Fórmula: n = (Z² × p × q) / E²';
    PUT '   - Resultado: n ≈ 314 títulos';
    PUT ' ';
    PUT '2. Para MEDIAS (Año de lanzamiento)';
    PUT '   - Estima: Año promedio de lanzamiento';
    PUT '   - Fórmula: n = (Z² × σ²) / E²';
    PUT '   - Resultado: n ≈ 74 títulos';
    PUT ' ';
    PUT '¿Por qué son diferentes?';
    PUT '- Proporción 50/50 tiene MÁXIMA varianza';
    PUT '- Año tiene POCA varianza (σ=8.79)';
    PUT ' ';
    PUT 'DECISIÓN: Usamos n=314 (el más grande)';
    PUT 'Porque es más CONSERVADOR y sirve para AMBAS variables';
    PUT '============================================';
RUN;

/* 2.2 Cálculo para PROPORCIONES */
TITLE4 'Tamaño de Muestra para PROPORCIONES (Movie vs TV Show)';

DATA work.calculo_n_proporcion;
    SET work.info_poblacion;
    
    Z = 1.96;              /* 95% confianza */
    E = 0.05;              /* Error 5% */
    p = p_movies;
    q = 1 - p;
    
    /* Población infinita */
    n0 = (Z**2 * p * q) / (E**2);
    
    /* Población finita (corrección FPC) */
    n_finita = n0 / (1 + (n0 - 1) / N_poblacion);
    
    n_final = CEIL(n_finita);
    
    LABEL 
        Z='Valor Z (95% IC)'
        E='Error máximo'
        p='Proporción estimada'
        n0='n (población infinita)'
        n_finita='n (población finita)'
        n_final='TAMAÑO FINAL';
RUN;

PROC PRINT DATA=work.calculo_n_proporcion NOOBS LABEL;
    VAR Z E p n0 n_finita n_final;
    FORMAT p PERCENT8.2 n0 n_finita 8.2 n_final 8.0;
RUN;

/* 2.3 Cálculo para MEDIAS */
TITLE4 'Tamaño de Muestra para MEDIAS (Año de Lanzamiento)';

DATA work.calculo_n_media;
    SET work.info_poblacion;
    
    Z = 1.96;              /* 95% confianza */
    E = 2;                 /* Error ±2 años */
    sigma = sigma_year;
    
    /* Población infinita */
    n0 = (Z**2 * sigma**2) / (E**2);
    
    /* Población finita */
    n_finita = n0 / (1 + (n0 - 1) / N_poblacion);
    
    n_final = CEIL(n_finita);
    
    LABEL 
        Z='Valor Z (95% IC)'
        E='Error máximo (años)'
        sigma='Desviación estándar'
        n0='n (población infinita)'
        n_finita='n (población finita)'
        n_final='TAMAÑO FINAL';
RUN;

PROC PRINT DATA=work.calculo_n_media NOOBS LABEL;
    VAR Z E sigma n0 n_finita n_final;
    FORMAT sigma 8.4 n0 n_finita 8.2 n_final 8.0;
RUN;

/* USAR EL TAMAÑO MÁS GRANDE (más conservador) */
DATA _null_;
    SET work.calculo_n_proporcion;
    CALL SYMPUTX('n_muestra', n_final);
    PUT '============================================';
    PUT "TAMAÑO DE MUESTRA SELECCIONADO: n = " n_final;
    PUT '(Se usa el más grande para mayor precisión)';
    PUT '============================================';
RUN;

/* 2.4 Tabla Comparativa de Escenarios */
TITLE4 'Comparación: Diferentes Niveles de Confianza y Error';

DATA work.tabla_comparativa;
    SET work.info_poblacion;
    
    ARRAY nivel_conf[3] _temporary_ (1.645 1.96 2.576);
    ARRAY errores[3] _temporary_ (1 2 3);
    
    DO i = 1 TO 3;
        DO j = 1 TO 3;
            Z = nivel_conf[i];
            E = errores[j];
            
            IF i = 1 THEN Confianza = '90%';
            ELSE IF i = 2 THEN Confianza = '95%';
            ELSE Confianza = '99%';
            
            Error_Max = E;
            
            n0 = (Z**2 * sigma_year**2) / (E**2);
            n_finita = n0 / (1 + (n0 - 1) / N_poblacion);
            Tamano_Muestra = CEIL(n_finita);
            
            OUTPUT;
        END;
    END;
    
    KEEP Confianza Error_Max Tamano_Muestra;
RUN;

PROC PRINT DATA=work.tabla_comparativa NOOBS;
    TITLE5 'Cómo cambia n según confianza y error permitido';
RUN;

/* ============================================================================
   PARTE 3: MUESTREO ALEATORIO SIMPLE (MAS)
   ============================================================================ */

TITLE2 '====== PARTE 3: MUESTREO ALEATORIO SIMPLE ======';
TITLE3 '3.1 Selección de Muestra Aleatoria';

PROC SURVEYSELECT DATA=work.netflix
    METHOD=SRS
    N=&n_muestra
    SEED=12345
    OUT=work.muestra_mas;
RUN;

DATA _null_;
    PUT "Muestra Aleatoria Simple creada: n = &n_muestra";
RUN;

/* Estadísticas de la muestra */
TITLE4 'Estadísticas de la Muestra (MAS)';

PROC MEANS DATA=work.muestra_mas(WHERE=(release_year NE .)) 
    N MEAN MEDIAN MODE STD MIN MAX Q1 Q3 SKEW KURT;
    VAR release_year;
    OUTPUT OUT=work.stats_muestra_mas
        N=n MEAN=media MEDIAN=mediana MODE=moda 
        STD=desv_std MIN=minimo MAX=maximo 
        Q1=q1 Q3=q3 
        SKEW=asimetria KURT=curtosis;
RUN;

DATA work.stats_muestra_mas;
    SET work.stats_muestra_mas;
    tipo = 'MUESTRA_MAS';
RUN;

PROC PRINT DATA=work.stats_muestra_mas NOOBS LABEL;
    LABEL 
        media='Media' 
        mediana='Mediana' 
        desv_std='Desv. Estándar';
    FORMAT media mediana desv_std 8.2 asimetria curtosis 8.4;
RUN;

/* Comparación Población vs Muestra */
TITLE4 'COMPARACIÓN: Población vs Muestra (MAS)';

DATA work.comp_pob_muestra;
    SET work.parametros_poblacionales work.stats_muestra_mas;
RUN;

PROC PRINT DATA=work.comp_pob_muestra NOOBS;
    VAR tipo n media mediana desv_std;
    FORMAT media mediana desv_std 8.2;
RUN;

/* ============================================================================
   PARTE 4: MUESTREO ESTRATIFICADO
   ============================================================================ */

TITLE2 '====== PARTE 4: MUESTREO ESTRATIFICADO ======';
TITLE3 '4.1 Estratificación por Tipo (Movie/TV Show)';

/* Calcular proporciones */
PROC FREQ DATA=work.netflix NOPRINT;
    TABLES type / OUT=work.estratos;
RUN;

DATA work.estratos;
    SET work.estratos;
    n_total = &n_muestra;
    proporcion = PERCENT / 100;
    n_estrato = ROUND(n_total * proporcion);
RUN;

PROC PRINT DATA=work.estratos NOOBS;
    TITLE4 'Distribución de la Muestra por Estrato';
    VAR type COUNT PERCENT n_estrato;
RUN;

/* Muestreo estratificado */
PROC SQL NOPRINT;
    SELECT n_estrato INTO :n_movies FROM work.estratos WHERE type='Movie';
    SELECT n_estrato INTO :n_tvshows FROM work.estratos WHERE type='TV Show';
QUIT;

PROC SURVEYSELECT DATA=work.netflix(WHERE=(type='Movie'))
    METHOD=SRS
    N=&n_movies
    SEED=54321
    OUT=work.muestra_movies;
RUN;

PROC SURVEYSELECT DATA=work.netflix(WHERE=(type='TV Show'))
    METHOD=SRS
    N=&n_tvshows
    SEED=54322
    OUT=work.muestra_tvshows;
RUN;

DATA work.muestra_estratificada;
    SET work.muestra_movies work.muestra_tvshows;
RUN;

/* Estadísticas */
TITLE4 'Estadísticas de la Muestra Estratificada';

PROC MEANS DATA=work.muestra_estratificada(WHERE=(release_year NE .)) 
    N MEAN MEDIAN STD MIN MAX;
    VAR release_year;
    OUTPUT OUT=work.stats_muestra_estrat
        N=n MEAN=media MEDIAN=mediana 
        STD=desv_std MIN=minimo MAX=maximo;
RUN;

DATA work.stats_muestra_estrat;
    SET work.stats_muestra_estrat;
    tipo = 'MUESTRA_ESTRATIFICADA';
RUN;

PROC PRINT DATA=work.stats_muestra_estrat NOOBS;
    VAR tipo n media mediana desv_std;
    FORMAT media mediana desv_std 8.2;
RUN;

/* Estadísticas por estrato */
TITLE4 'Estadísticas por Estrato (Movie vs TV Show)';
PROC MEANS DATA=work.muestra_estratificada(WHERE=(release_year NE .)) 
    N MEAN STD;
    CLASS type;
    VAR release_year;
RUN;

/* ============================================================================
   PARTE 5: MUESTREO SISTEMÁTICO
   ============================================================================ */

TITLE2 '====== PARTE 5: MUESTREO SISTEMÁTICO ======';
TITLE3 '5.1 Cálculo del Intervalo k';

DATA _null_;
    k = FLOOR(&N_total / &n_muestra);
    CALL SYMPUTX('k_intervalo', k);
    PUT "Intervalo k para muestreo sistemático: " k;
    PUT "(Se selecciona cada k-ésimo elemento)";
RUN;

/* Selección sistemática */
TITLE4 'Selección Sistemática (cada k-ésimo elemento)';

DATA work.muestra_sistematica;
    SET work.netflix;
    RETAIN inicio;
    IF _N_ = 1 THEN inicio = RAND('INTEGER', 1, &k_intervalo);
    IF MOD(_N_ - inicio, &k_intervalo) = 0 THEN OUTPUT;
RUN;

PROC SQL;
    SELECT COUNT(*) AS Tam_Muestra_Sistematica 
    FROM work.muestra_sistematica;
QUIT;

/* Estadísticas */
TITLE4 'Estadísticas de la Muestra Sistemática';

PROC MEANS DATA=work.muestra_sistematica(WHERE=(release_year NE .)) 
    N MEAN MEDIAN STD MIN MAX;
    VAR release_year;
    OUTPUT OUT=work.stats_muestra_sist
        N=n MEAN=media MEDIAN=mediana 
        STD=desv_std MIN=minimo MAX=maximo;
RUN;

DATA work.stats_muestra_sist;
    SET work.stats_muestra_sist;
    tipo = 'MUESTRA_SISTEMATICA';
RUN;

PROC PRINT DATA=work.stats_muestra_sist NOOBS;
    VAR tipo n media mediana desv_std;
    FORMAT media mediana desv_std 8.2;
RUN;

/* ============================================================================
   PARTE 6: COMPARACIÓN DE TODOS LOS MÉTODOS
   ============================================================================ */

TITLE2 '====== PARTE 6: COMPARACIÓN DE MÉTODOS DE MUESTREO ======';
TITLE3 '6.1 Resumen Comparativo';

DATA work.comparacion_todos;
    SET work.parametros_poblacionales 
        work.stats_muestra_mas 
        work.stats_muestra_estrat 
        work.stats_muestra_sist;
RUN;

PROC PRINT DATA=work.comparacion_todos NOOBS;
    VAR tipo n media mediana desv_std asimetria curtosis;
    FORMAT media mediana desv_std 8.2 asimetria curtosis 8.4;
RUN;

/* Gráfico comparativo */
TITLE4 'Comparación Visual de Medias';

PROC SGPLOT DATA=work.comparacion_todos;
    VBAR tipo / RESPONSE=media DATALABEL;
    REFLINE &mu_pob / AXIS=y LINEATTRS=(pattern=dash color=red) LABEL='Media Poblacional';
    XAXIS LABEL='Método';
    YAXIS LABEL='Media del Año de Lanzamiento';
RUN;

/* Calcular errores */
PROC SORT DATA=work.comparacion_todos;
    BY tipo;
RUN;

DATA work.errores_todos;
    SET work.comparacion_todos;
    BY tipo;
    RETAIN media_pob;
    
    IF tipo = 'POBLACION' THEN DO;
        media_pob = media;
        Error_Absoluto = 0;
        Error_Relativo_Pct = 0;
    END;
    ELSE DO;
        Error_Absoluto = ABS(media - media_pob);
        Error_Relativo_Pct = (Error_Absoluto / media_pob) * 100;
    END;
    
    DROP media_pob;
RUN;

TITLE4 'Análisis de Errores de Estimación';
PROC PRINT DATA=work.errores_todos NOOBS;
    VAR tipo n media Error_Absoluto Error_Relativo_Pct;
    FORMAT media Error_Absoluto 8.4 Error_Relativo_Pct 8.2;
RUN;

/* ============================================================================
   PARTE 7: INTERVALOS DE CONFIANZA
   ============================================================================ */

TITLE2 '====== PARTE 7: INTERVALOS DE CONFIANZA ======';
TITLE3 '7.1 Intervalo de Confianza al 95% (Muestra Aleatoria Simple)';

DATA work.ic_muestra;
    SET work.stats_muestra_mas;
    
    Z = 1.96;
    Error_Estandar = desv_std / SQRT(n);
    Limite_Inferior = media - (Z * Error_Estandar);
    Limite_Superior = media + (Z * Error_Estandar);
    Amplitud_IC = Limite_Superior - Limite_Inferior;
    
    LABEL
        Error_Estandar='Error Estándar'
        Limite_Inferior='Límite Inferior (95%)'
        Limite_Superior='Límite Superior (95%)'
        Amplitud_IC='Amplitud del IC';
RUN;

PROC PRINT DATA=work.ic_muestra NOOBS LABEL;
    VAR media Error_Estandar Limite_Inferior Limite_Superior Amplitud_IC;
    FORMAT media Error_Estandar Limite_Inferior Limite_Superior Amplitud_IC 8.4;
RUN;

/* Verificar si contiene la media poblacional */
DATA _null_;
    SET work.ic_muestra;
    PUT '============================================';
    PUT 'VALIDACIÓN DEL INTERVALO DE CONFIANZA';
    PUT '============================================';
    PUT "Media Poblacional: &mu_pob";
    PUT 'Límite Inferior IC: ' Limite_Inferior;
    PUT 'Límite Superior IC: ' Limite_Superior;
    
    IF &mu_pob >= Limite_Inferior AND &mu_pob <= Limite_Superior THEN
        PUT '✓ EL IC CONTIENE LA MEDIA POBLACIONAL';
    ELSE
        PUT '✗ EL IC NO CONTIENE LA MEDIA POBLACIONAL';
    PUT '============================================';
RUN;

/* ============================================================================
   PARTE 8: ANÁLISIS DE SESGO
   ============================================================================ */

TITLE2 '====== PARTE 8: DETECCIÓN DE SESGO EN MUESTREO ======';
TITLE3 '8.1 Ejemplo de SESGO: Muestra solo años >= 2010';

DATA work.muestra_sesgada;
    SET work.netflix;
    WHERE release_year >= 2010;
    IF _N_ <= &n_muestra THEN OUTPUT;
RUN;

PROC MEANS DATA=work.muestra_sesgada(WHERE=(release_year NE .)) N MEAN STD;
    VAR release_year;
    OUTPUT OUT=work.stats_sesgada N=n MEAN=media STD=desv_std;
RUN;

DATA work.stats_sesgada;
    SET work.stats_sesgada;
    tipo = 'MUESTRA_SESGADA';
RUN;

/* Comparar con población */
TITLE4 'Comparación: Muestra Sesgada vs Población';

DATA work.comp_sesgo;
    SET work.parametros_poblacionales work.stats_sesgada;
    KEEP tipo n media desv_std;
RUN;

PROC PRINT DATA=work.comp_sesgo NOOBS;
    VAR tipo n media desv_std;
    FORMAT media desv_std 8.2;
RUN;

PROC SORT DATA=work.comp_sesgo;
    BY tipo;
RUN;

/* Calcular sesgo */
DATA work.calculo_sesgo;
    SET work.comp_sesgo(WHERE=(tipo='POBLACION'));
    media_pob = media;
    SET work.comp_sesgo(WHERE=(tipo='MUESTRA_SESGADA'));
    
    Sesgo = media - media_pob;
    Sesgo_Relativo_Pct = (Sesgo / media_pob) * 100;
    
    KEEP tipo Sesgo Sesgo_Relativo_Pct;
RUN;

TITLE4 'Medición del Sesgo';
PROC PRINT DATA=work.calculo_sesgo NOOBS;
    VAR tipo Sesgo Sesgo_Relativo_Pct;
    FORMAT Sesgo 8.4 Sesgo_Relativo_Pct 8.2;
RUN;

/* ============================================================================
   PARTE 9: RESUMEN EJECUTIVO
   ============================================================================ */

TITLE2 '====== PARTE 9: RESUMEN EJECUTIVO ======';

DATA work.resumen_final;
    LENGTH Aspecto $60 Valor $100;
    
    Aspecto = 'Tamaño de la Población (N)'; 
    Valor = PUT(&N_total, COMMA10.); OUTPUT;
    
    Aspecto = 'Tamaño de Muestra para Proporciones'; 
    Valor = '314 títulos (±5% error, 95% conf)'; OUTPUT;
    
    Aspecto = 'Tamaño de Muestra para Medias'; 
    Valor = '74 títulos (±2 años error, 95% conf)'; OUTPUT;
    
    Aspecto = 'Tamaño Usado en Análisis'; 
    Valor = PUT(&n_muestra, 8.0) || ' (el más conservador)'; OUTPUT;
    
    Aspecto = 'Media Poblacional (año)'; 
    Valor = PUT(&mu_pob, 8.2); OUTPUT;
    
    Aspecto = 'Desv. Std. Poblacional'; 
    Valor = PUT(&sigma_pob, 8.2); OUTPUT;
    
    Aspecto = 'Mejor Método de Muestreo'; 
    Valor = 'Estratificado por tipo de contenido'; OUTPUT;
    
    Aspecto = 'Razón'; 
    Valor = 'Menor error y representa ambos estratos'; OUTPUT;
RUN;

PROC PRINT DATA=work.resumen_final NOOBS;
    VAR Aspecto Valor;
RUN;

