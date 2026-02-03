ARG codename=focal
ARG python_version=3.8
ARG odoo_version
FROM ghcr.io/oca/oca-ci/py${python_version}-odoo${odoo_version}:latest
ENV LANG=C.UTF-8
ENV ODOO_VERSION=$odoo_version
USER root

# SG: use uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

ARG odoo_version
# Install Odoo requirements (use ADD for correct layer caching).
# We use requirements from our Odoo fork for easier maintenance of older versions.
# ADD https://api.github.com/repos/steingabelgaard/odoo/git/refs/heads/$odoo_version /tmp/branch.json

# Use the commit SHA from JSON to download exact requirements.txt
# RUN SHA=$(jq -r .object.sha /tmp/branch.json) \
# && curl -sSL "https://raw.githubusercontent.com/steingabelgaard/odoo/${SHA}/requirements.txt" \
#    -o /tmp/ocb-requirements.txt
# The sed command is to use the latest version of gevent and greenlet. The
# latest version works with all versions of Odoo that we support here, and the
# oldest pinned in Odoo's requirements.txt don't have wheels, and don't build
# anymore with the latest cython.
# RUN sed -i -E "s/^(gevent|greenlet)==.*/\1/" /tmp/ocb-requirements.txt \
# && pip install --no-cache-dir \
#      -r /tmp/ocb-requirements.txt \
#       packaging

# Install Open Upgrade req. from our fork. We add often used packages to these
# ADD https://raw.githubusercontent.com/steingabelgaard/OpenUpgrade/$odoo_version/requirements.txt /tmp/sgou-requirements.txt
# RUN pip install --no-cache-dir -r /tmp/sgou-requirements.txt


COPY bin/* /usr/local/bin/

ENV ODOO_VERSION=$odoo_version
ENV PGHOST=postgres
ENV PGUSER=odoo
ENV PGPASSWORD=odoo
ENV PGDATABASE=odoo
# This PEP 503 index uses odoo addons from OCA and redirects the rest to PyPI,
# in effect hiding all non-OCA Odoo addons that are on PyPI.
ENV PIP_INDEX_URL=https://wheelhouse.odoo-community.org/oca-simple-and-pypi
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_PYTHON_VERSION_WARNING=1
# Control addons discovery. INCLUDE and EXCLUDE are comma-separated list of
# addons to include (default: all) and exclude (default: none)
ENV ADDONS_DIR=.
ENV ADDONS_PATH=/opt/odoo/addons
ENV INCLUDE=
ENV EXCLUDE=
ENV OCA_GIT_USER_NAME=sgrunbot
ENV OCA_GIT_USER_EMAIL=sgrunbot@adm.steingabelgaard.dk
ENV OCA_ENABLE_CHECKLOG_ODOO=
ENV SG_USE_UV=true

# Install build dependencies for python libs commonly used by Odoo and OCA
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq --no-install-recommends \
       
       # need libjpeg to build older pillow versions
       libjpeg-dev \
       # for pycups
       libcups2-dev \
       # for pdftotext
       libpoppler-cpp-dev \
       # for mysqlclient \
       default-libmysqlclient-dev \
    && apt-get clean

# Install commonly used OCA addons
# ADD https://api.github.com/repos/steingabelgaard/odoo/git/refs/heads/$odoo_version /tmp/branch.json

# Use the commit SHA from JSON to download exact requirements.txt
# RUN SHA=$(jq -r .object.sha /tmp/branch.json) \
#  && curl -sSL "https://raw.githubusercontent.com/steingabelgaard/odoo/${SHA}/oca-addons.txt" \
#    -o /tmp/oca-addons-requirements.txt

# SG: Install our most used OCA addons
# RUN pip install --no-cache-dir \
#      -r /tmp/oca-addons-requirements.txt \
