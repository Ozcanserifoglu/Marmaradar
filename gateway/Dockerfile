FROM krakend:2.13

COPY config/krakend.tmpl /etc/krakend/krakend.tmpl
COPY config/settings/prod /etc/krakend/settings/prod

ENV FC_ENABLE=1
ENV FC_SETTINGS=/etc/krakend/settings/prod

EXPOSE 8080

CMD ["run", "-c", "/etc/krakend/krakend.tmpl"]
