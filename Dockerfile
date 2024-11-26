#FROM innovanon/ia_elevate      AS elevate
#FROM innovanon/ia_check_output AS check_output
FROM ia_elevate      AS elevate
FROM ia_check_output AS check_output

COPY --from=elevate /tmp/py/ /tmp/py/
RUN pip install --no-cache-dir --upgrade -r requirements.txt
RUN pip install --no-cache-dir --upgrade .
RUN rm -rf /tmp/py/

COPY ./ ./
RUN pip install --no-cache-dir --upgrade -r requirements.txt
RUN pip install --no-cache-dir --upgrade .
ENTRYPOINT ["python", "-m", "ia_apt"]
