# PyTorch MODERNO (CUDA 12.8 / cu128) para GPUs Blackwell (RTX PRO 6000, sm_120). Python 3.10.
FROM python:3.10-slim

WORKDIR /app

# Herramientas + librerías de sistema que SadTalker necesita
RUN apt-get update && \
    apt-get install -y git wget ffmpeg build-essential cmake libgl1 libglib2.0-0 libsndfile1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clonar SadTalker y copiar el worker encima
RUN git clone https://github.com/OpenTalker/SadTalker.git /app/SadTalker
WORKDIR /app/SadTalker
COPY app/ /app/SadTalker

# 1) PyTorch NUEVO con CUDA 12.8 (tiene kernels para Blackwell sm_120) + SDK runpod al día
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 && \
    pip install --no-cache-dir boto3 runpod requests

# 2) Dependencias de SadTalker SIN los pines viejos de torch/numpy (romperían lo nuevo);
#    numpy<2 porque varias libs viejas (numba, basicsr) no soportan numpy 2.x
RUN sed -i '/^torch/d; /^numpy/d' requirements.txt && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir "numpy<2"

# 3) Parche: basicsr/gfpgan/facexlib importan torchvision.transforms.functional_tensor (eliminado en torchvision nuevo)
RUN find /usr/local/lib -name "*.py" -exec sed -i 's/torchvision\.transforms\.functional_tensor/torchvision.transforms.functional/g' {} +

# 4) Hornear los modelos en la imagen (no se bajan en caliente)
RUN cd /app/SadTalker && python -c "import sys; from utils.file_utils import sync_checkpoints; r,e=sync_checkpoints(); print('bake:', e); sys.exit(1 if e else 0)"

CMD ["python", "-u", "/app/SadTalker/handler.py"]
