# Base image
FROM python:3.10-slim

# Use bash shell with pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set the working directory
WORKDIR /

# Update and upgrade the system packages (Worker Template)
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install git ffmpeg libgl1-mesa-glx libglib2.0-0 -y &&\
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies (Worker Template)
COPY builder/requirements.txt /requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip && \
    pip install --upgrade -r /requirements.txt --no-cache-dir && \
    rm /requirements.txt

# Install deforum-stable-diffusion
RUN git clone https://github.com/justinmerrell/deforum-stable-diffusion.git && \
    cd deforum-stable-diffusion && \
    git reset --hard 3358d9aea454302f895f9f37f2344515c76a0adf

WORKDIR /deforum-stable-diffusion

# Add src files (Worker Template)
ADD src .

# Cache Models
COPY builder/cache_models.py cache_models.py
# We importing some packages from deforum repo for model downloading
ENV PYTHONPATH="${PYTHONPATH}:/deforum-stable-diffusion/src"
RUN python cache_models.py
RUN rm cache_models.py

# Create symlink (deforum has hardcoded paths for diffusion_models_cache for simplicity all models are stored in models folder)
RUN ln -s /deforum-stable-diffusion/models /deforum-stable-diffusion/diffusion_models_cache

# Cleanup section (Worker Template)
RUN apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

CMD python -u rp_handler.py
