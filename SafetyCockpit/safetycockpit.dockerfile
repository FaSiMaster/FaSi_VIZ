FROM baudifasi.azurecr.io/alpine-rshiny:latest
RUN addgroup -S -g 1001 safetycockpit \
    && adduser safetycockpit -S -D -H -u 1001 -G safetycockpit \
    && chown -R safetycockpit:safetycockpit /usr/bin/Rscript \
    && mkdir -p /home/safetycockpit/.cache/R \
    && chown -R safetycockpit:safetycockpit /home/safetycockpit/.cache/R \
    && sed -i 's/\[ODBC Driver 18 for SQL Server]/\[SQL Server\]/' /etc/odbcinst.ini
WORKDIR /safetycockpit
COPY --chown=safetycockpit:safetycockpit . /safetycockpit

USER safetycockpit
EXPOSE 4629
CMD [ "Rscript","/safetycockpit/app.R","--no-save" ]