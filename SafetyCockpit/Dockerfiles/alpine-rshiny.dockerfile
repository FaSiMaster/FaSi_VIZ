FROM alpine:3.20.2
RUN apk add --no-cache --no-progress --quiet R curl \
    && apk add --no-cache --no-progress --quiet gdal proj geos unixodbc libsodium sqlite-libs udunits libxml2 openssl fontconfig freetype harfbuzz fribidi libpng cairo\
    && apk add --no-cache --no-progress --quiet --virtual .build_deps make gcc g++ linux-headers gdal-dev proj-dev geos-dev unixodbc-dev libsodium-dev R-dev tzdata cmake sqlite-dev udunits-dev clipboard libxml2-dev curl-dev openssl-dev fontconfig-dev freetype-dev harfbuzz-dev fribidi-dev libpng-dev cairo-dev pkgconf\
    && ln -s /usr/share/zoneinfo/Europe/Brussels /etc/localtime \
    && curl -O https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/msodbcsql18_18.4.1.1-1_amd64.apk \
    && apk add --allow-untrusted msodbcsql18_18.4.1.1-1_amd64.apk -q \
    && rm msodbcsql18_18.4.1.1-1_amd64.apk \
    && mkdir -p /usr/share/doc/R/html \
    && R -e "install.packages('codetools',repos='https://ftp.fau.de/cran/'); \
            install.packages('base64enc',repos='https://ftp.fau.de/cran/'); \
            install.packages('bsicons',repos='https://ftp.fau.de/cran/'); \
            install.packages('bslib',repos='https://ftp.fau.de/cran/'); \
            install.packages('config',repos='https://ftp.fau.de/cran/'); \
            install.packages('DBI',repos='https://ftp.fau.de/cran/'); \
            install.packages('dbplyr',repos='https://ftp.fau.de/cran/'); \
            install.packages('dplyr',repos='https://ftp.fau.de/cran/'); \
            install.packages('DT',repos='https://ftp.fau.de/cran/'); \
            install.packages('forcats',repos='https://ftp.fau.de/cran/'); \
            install.packages('htmltools',repos='https://ftp.fau.de/cran/'); \
            install.packages('kableExtra',repos='https://ftp.fau.de/cran/'); \
            install.packages('knitr',repos='https://ftp.fau.de/cran/'); \
            install.packages('lubridate',repos='https://ftp.fau.de/cran/'); \
            install.packages('MASS',repos='https://ftp.fau.de/cran/'); \
            install.packages('odbc',repos='https://ftp.fau.de/cran/'); \
            install.packages('openxlsx',repos='https://ftp.fau.de/cran/'); \
            install.packages('plotly',repos='https://ftp.fau.de/cran/'); \
            install.packages('purrr',repos='https://ftp.fau.de/cran/'); \
            install.packages('ranger',repos='https://ftp.fau.de/cran/'); \
            install.packages('rclipboard',repos='https://ftp.fau.de/cran/'); \
            install.packages('rlang',repos='https://ftp.fau.de/cran/'); \
            install.packages('shiny',repos='https://ftp.fau.de/cran/'); \
            install.packages('shinyauthr',repos='https://ftp.fau.de/cran/'); \
            install.packages('shinycssloaders',repos='https://ftp.fau.de/cran/'); \
            install.packages('shinyFeedback',repos='https://ftp.fau.de/cran/'); \
            install.packages('shinyjs',repos='https://ftp.fau.de/cran/'); \
            install.packages('shinyWidgets',repos='https://ftp.fau.de/cran/'); \
            install.packages('stringr',repos='https://ftp.fau.de/cran/'); \
            install.packages('tibble',repos='https://ftp.fau.de/cran/'); \
            install.packages('tidyr',repos='https://ftp.fau.de/cran/'); \
            install.packages('dbplyr',repos='https://ftp.fau.de/cran/'); \
            install.packages('pkgload',repos='https://ftp.fau.de/cran/');\
            install.packages('writexl',repos='https://ftp.fau.de/cran/');"
            
# Install sodium separately
RUN R -e "install.packages('sodium', repos='https://ftp.fau.de/cran/')" || (echo "Terra installation failed" && exit 1)

RUN R -e "install.packages('sf', repos='https://ftp.fau.de/cran/')" || (echo "SF installation failed" && exit 1)

# Install terra separately
RUN R -e "install.packages('terra', repos='https://ftp.fau.de/cran/')" || (echo "Terra installation failed" && exit 1)

# Install leaflet separately
RUN R -e "install.packages('leaflet', repos='https://ftp.fau.de/cran/')" || (echo "Leaflet installation failed" && exit 1)

RUN R -e "required <- c('leaflet', 'sf', 'terra', 'shinycssloaders'); \
            installed <- rownames(installed.packages()); \
            missing <- setdiff(required, installed); \
            if(length(missing) > 0) { \
              cat('ERROR: Missing packages:', paste(missing, collapse=', '), '\n'); \
              quit(status=1); \
            } else { \
              cat('All required packages installed successfully\n'); \
            }" \

    && Rscript -e 'writeLines(rownames(installed.packages()))'
    