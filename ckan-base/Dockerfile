FROM ckan/ckan-base:2.11.3

ARG XLOADER_VERSION=${XLOADER_VERSION}

# Install any extensions needed by your CKAN instance
# See the official ckan-docker repo (https://github.com/ckan/ckan-docker)
# for more details and examples

USER root

# Install the XLoader extension
RUN pip3 install -U pip && \ 
    cd ${SRC_DIR} && \
    pip3 install -e git+https://github.com/ckan/ckanext-xloader.git@${XLOADER_VERSION}#egg=ckanext-xloader && \
    pip3 install -r ckanext-xloader/requirements.txt && \
    pip3 install -U requests[security]

# Copy custom initialization scripts
COPY --chown=ckan-sys:ckan-sys docker-entrypoint.d/* /docker-entrypoint.d/

# Apply any patches needed to CKAN core or any of the built extensions (not the
# runtime mounted ones)
COPY --chown=ckan-sys:ckan-sys patches ${APP_DIR}/patches

# Copy override files in setup/
COPY setup/prerun.py.override ${APP_DIR}/prerun.py
COPY setup/start_ckan.sh.override ${APP_DIR}/start_ckan.sh

# Ownership and permission changes for Openshift
RUN mkdir -p ${APP_DIR} /etc/ckan /var/lib/ckan \
    && chgrp -R 0 ${APP_DIR} /etc/ckan /var/lib/ckan \
    && chmod -R g+rwX ${APP_DIR} /etc/ckan /var/lib/ckan \
    && chmod g+s ${APP_DIR} /etc/ckan /var/lib/ckan

RUN chmod g+rx ${APP_DIR}/start_ckan.sh

USER ckan

RUN for d in $APP_DIR/patches/*; do \
        if [ -d $d ]; then \
            for f in `ls $d/*.patch | sort -g`; do \
                cd $SRC_DIR/`basename "$d"` && echo "$0: Applying patch $f to $SRC_DIR/`basename $d`"; patch -p1 < "$f" ; \
            done ; \
        fi ; \
    done