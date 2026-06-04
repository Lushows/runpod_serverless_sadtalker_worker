# Use the official Python 3.8 image from the Docker Hub
FROM python:3.8-slim

# Set the working directory inside the container
WORKDIR /app

# Install dependencies and essential tools (incl. compilers + libs SadTalker needs)
RUN apt-get update && \
    apt-get install -y git ffmpeg build-essential cmake libgl1 libglib2.0-0 libsndfile1 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone the SadTalker repository
RUN git clone https://github.com/OpenTalker/SadTalker.git /app/SadTalker

# Change to the SadTalker directory
WORKDIR /app/SadTalker

COPY app/ /app/SadTalker

# Install PyTorch with CUDA support and other dependencies
# torch viejo se baja del listado completo torch_stable (más confiable que el índice cu113)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch==1.12.1+cu113 torchvision==0.13.1+cu113 torchaudio==0.12.1 -f https://download.pytorch.org/whl/torch_stable.html && \
    pip install --no-cache-dir boto3 runpod==1.6.0 && \
    pip install --no-cache-dir -r requirements.txt

# Set the entrypoint
CMD ["python", "-u", "/app/SadTalker/handler.py"]
