# Quick Start Guide for Vast.ai + Jupyter Terminal

## Step-by-Step Setup

### 1. Connect to Your Vast.ai Instance
- Open Jupyter terminal from your Vast.ai instance dashboard
- Navigate to where you want to work (or clone/upload Autolume)

### 2. Setup Environment (Copy & Paste This)

```bash
# Navigate to autolume directory (adjust path as needed)
cd ~/autolume

# Run setup script (auto-installs uv if needed)
# This will install all dependencies needed for training (skips optional packages)
bash setup_venv_jupyter.sh

# Activate the virtual environment
source .venv/bin/activate
```

**Note:** You'll need to run `source .venv/bin/activate` each time you open a new terminal session.

### 3. Verify GPU is Working

```bash
# Check GPU
nvidia-smi

# Verify PyTorch sees the GPU
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, GPUs: {torch.cuda.device_count()}')"
```

### 4. Prepare Your Dataset

Upload your dataset to the instance:
- Use Jupyter file browser to upload
- Or use `scp` from your local machine
- Place it in a directory like `~/datasets/my-dataset/`

### 5. Start Training

```bash
# Make sure venv is activated (you should see (.venv) in prompt)
source .venv/bin/activate

# Basic training command
python train_wrapper.py \
    --outdir=./training-runs \
    --cfg=stylegan2 \
    --data=~/datasets/my-dataset \
    --gpus=1 \
    --batch=4 \
    --gamma=10.0 \
    --resolution="(512,512)" \
    --mirror=True \
    --aug=ada
```

## Important Tips for Vast.ai

### Keep Training Running After Disconnect

Use `screen` to keep training running even if you disconnect:

```bash
# Install screen (if not already installed)
sudo apt-get update && sudo apt-get install -y screen

# Start a screen session
screen -S training

# Activate venv and run training
source .venv/bin/activate
python train.py [your options]

# Detach: Press Ctrl+A, then D
# Reattach later: screen -r training
# List sessions: screen -ls
```

### Monitor Training

In a separate terminal (or screen session):

```bash
# Watch GPU usage
watch -n 1 nvidia-smi

# Check disk space
df -h

# Monitor training output
tail -f training-runs/*/log.txt
```

### Download Results

Before your instance expires:
- Use Jupyter file browser to download `training-runs/` folder
- Or use `scp` from your local machine:
  ```bash
  scp -r user@vast-ai-instance:~/autolume/training-runs ./
  ```

## Quick Commands Reference

```bash
# Activate venv (do this first in each terminal)
source .venv/bin/activate

# Check GPU
nvidia-smi

# Test training config (dry run)
python train_wrapper.py --outdir=./test --cfg=stylegan2 --data=../datasets/test --gpus=1 --batch=4 --gamma=10.0 --resolution="(512,512)" --dry-run

# Resume from checkpoint
python train_wrapper.py [same options] --resume=./training-runs/00000-*/network-snapshot-*.pkl
```

## Common Issues

**"Command not found: uv"**
- The setup script should install it automatically
- Or manually: `curl -LsSf https://astral.sh/uv/install.sh | sh && export PATH="$HOME/.cargo/bin:$PATH"`

**"Failed to build ndi-python or pyaudio"**
- These are optional packages not needed for training
- The setup script now uses `requirements-training.txt` which excludes them
- If you need them later, install system libraries first (see README)

**"CUDA not available"**
- Check Vast.ai instance has GPU: `nvidia-smi`
- Verify PyTorch installation: `python -c "import torch; print(torch.cuda.is_available())"`

**"Out of memory"**
- Reduce batch size: `--batch=2` or `--batch=1`
- Use `--batch-gpu=1` to limit per-GPU batch

**"Venv not activated"**
- You should see `(.venv)` in your prompt
- Run: `source .venv/bin/activate`

**"AttributeError: fps" or "ModuleNotFoundError: pkg_resources"**
- Make sure you're using `train_wrapper.py` not `train.py` for command-line training
- Install setuptools: `uv pip install "setuptools<65"`
- The wrapper automatically handles missing parameters like `fps`

**"Resolution parsing error"**
- Always quote the resolution: `--resolution="(512,512)"` not `--resolution=(512,512)`
- The wrapper fixes click's tuple parsing automatically
