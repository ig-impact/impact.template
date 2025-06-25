# ─────────── BUILD STAGE ───────────
FROM rocker/r-ver:4.5 AS builder
ENV RENV_CONFIG_AUTO_RESTORE_ENABLED=FALSE
WORKDIR /app

# system libs for igraph, nanonext, etc.
RUN apt-get update && apt-get install -y \
	libxml2-dev libssl-dev libcurl4-openssl-dev \
	cmake \
	libglpk-dev \
	xz-utils \
	libnode-dev \
	pandoc \
	&& rm -rf /var/lib/apt/lists/*

# copy in renv config + project
COPY renv.lock renv.lock
COPY renv/activate.R renv/activate.R
COPY .Rprofile .Rprofile

COPY R/ R/
COPY _targets.R _targets.R
COPY _targets_packages.R _targets_packages.R
COPY run_pipeline.R run_pipeline.R

# now restore with pak-enabled renv
RUN Rscript -e "renv::restore(prompt = FALSE)"

# ─────────── RUNTIME STAGE ───────────
FROM rocker/r-ver:4.5
WORKDIR /app

# bring in runtime-only deps
RUN apt-get update && apt-get install -y \
	libglpk40 \
	cmake \
	xz-utils \
	libcurl4-openssl-dev \
	libglpk-dev \
	libnode-dev\
	libxml2-dev \
	pandoc \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=builder /app /app

RUN useradd -m appuser && chown -R appuser /app
USER appuser

RUN Rscript -e "renv::repair()"
CMD ["Rscript", "run_pipeline.R"]
