# Autolume Training Guide for Cloud GPU (Vast.ai / Jupyter Terminal)

## Step 1: Setup Virtual Environment on Vast.ai

### For Jupyter Terminal:

1. **Navigate to your project directory** (where you uploaded/cloned Autolume):
```bash
cd /path/to/autolume
```

2. **Run the setup script** (it will auto-install uv if needed):
```bash
bash setup_venv_jupyter.sh
```

Or use the regular setup script:
```bash
bash setup_venv.sh
```

**Note:** 
- If `uv` is not installed, the Jupyter script will install it automatically. Otherwise, install it manually:
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.cargo/bin:$PATH"
  ```
- The setup script uses `requirements-training.txt` which excludes optional packages (`ndi-python`, `pyaudio`) that require system libraries and aren't needed for training.

3. **After setup completes, activate the virtual environment**:
```bash
source .venv/bin/activate
```

**Important:** In Jupyter terminal, you need to activate the venv in each new terminal session. The prompt should show `(.venv)` when activated.

### Quick Setup (One-liner for Jupyter):

If you prefer to do it step by step in Jupyter terminal:

```bash
# Install uv if needed
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.cargo/bin:$PATH"

# Create venv
uv venv --python 3.10 .venv

# Activate venv
source .venv/bin/activate

# Install dependencies
uv pip install -r requirements.txt

# Verify CUDA
python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'GPUs: {torch.cuda.device_count()}')"
```

## Step 2: Prepare Your Dataset

Before training, you need to prepare your dataset. The dataset can be:
- A directory containing images
- A ZIP file containing images

Place your dataset in a location accessible to the training script.

## Step 3: Start Training

### Basic Training Command

Here's a basic training command structure:

```bash
python train_wrapper.py \
    --outdir=./training-runs \
    --cfg=stylegan2 \
    --data=/path/to/your/dataset \
    --gpus=1 \
    --batch=4 \
    --gamma=10.0 \
    --resolution="(512,512)" \
    --mirror=True \
    --aug=ada
```

**Note:** Use `train_wrapper.py` instead of `train.py` for command-line training. The `train.py` script is designed to be called from the GUI interface.

### Required Parameters

- `--outdir`: Directory where training results will be saved
- `--cfg`: Configuration type - choose one:
  - `stylegan2` - StyleGAN2 architecture
  - `stylegan3-t` - StyleGAN3 with translation equivariance
  - `stylegan3-r` - StyleGAN3 with rotation equivariance
- `--data`: Path to your training dataset (directory or ZIP file)
- `--gpus`: Number of GPUs to use (typically 1 for cloud GPU)
- `--batch`: Total batch size (must be divisible by number of GPUs)
- `--gamma`: R1 regularization weight (common values: 10.0 for StyleGAN2, 6.6-8.2 for StyleGAN3)
- `--resolution`: Dataset resolution as a tuple, e.g., `(512,512)` or `(1024,1024)`

### Common Optional Parameters

- `--mirror=True`: Enable horizontal flips for data augmentation
- `--aug=ada`: Augmentation mode (`ada`, `fixed`, or `noaug`)
- `--kimg=25000`: Total training duration in thousands of images (default: 25000)
- `--snap=50`: How often to save snapshots (default: 50)
- `--resume=/path/to/checkpoint.pkl`: Resume training from a checkpoint
- `--workers=4`: Number of data loader worker processes (default: 3)

### Example Training Commands

#### StyleGAN2 Training (512x512)
```bash
python train_wrapper.py \
    --outdir=./training-runs \
    --cfg=stylegan2 \
    --data=./datasets/my-dataset \
    --gpus=1 \
    --batch=4 \
    --gamma=10.0 \
    --resolution="(512,512)" \
    --mirror=True \
    --aug=ada \
    --kimg=25000 \
    --snap=50
```

#### StyleGAN3-T Training (1024x1024)
```bash
python train_wrapper.py \
    --outdir=./training-runs \
    --cfg=stylegan3-t \
    --data=./datasets/my-dataset \
    --gpus=1 \
    --batch=4 \
    --gamma=8.2 \
    --resolution="(1024,1024)" \
    --mirror=True \
    --aug=ada
```

#### Fine-tuning from Pre-trained Model
```bash
python train_wrapper.py \
    --outdir=./training-runs \
    --cfg=stylegan2 \
    --data=./datasets/my-dataset \
    --gpus=1 \
    --batch=4 \
    --gamma=10.0 \
    --resolution="(512,512)" \
    --resume=https://api.ngc.nvidia.com/v2/models/nvidia/research/stylegan2/versions/1/files/stylegan2-ffhq-512x512.pkl \
    --kimg=5000 \
    --snap=5
```

### Dry Run (Test Configuration)

Before starting actual training, you can test your configuration:

```bash
python train_wrapper.py \
    --outdir=./training-runs \
    --cfg=stylegan2 \
    --data=./datasets/my-dataset \
    --gpus=1 \
    --batch=4 \
    --gamma=10.0 \
    --resolution="(512,512)" \
    --dry-run
```

This will print the training configuration without starting training.

## Tips for Vast.ai / Cloud GPU Training

1. **Monitor GPU Usage**: Use `nvidia-smi` or `watch -n 1 nvidia-smi` to monitor GPU utilization in real-time
2. **Batch Size**: Start with a small batch size (4-8) and increase if you have GPU memory. Check available GPU memory with `nvidia-smi`
3. **Checkpoints**: Training saves snapshots regularly - you can resume from any checkpoint if the instance disconnects
4. **Training Time**: Training can take days or weeks depending on dataset size and resolution
5. **Storage**: Ensure you have enough disk space for training outputs (can be 10s of GB). Check with `df -h`
6. **Keep Session Alive**: In Jupyter, keep a terminal open or use `screen`/`tmux` for long training sessions:
   ```bash
   # Install screen if needed
   apt-get update && apt-get install -y screen
   
   # Start a screen session
   screen -S training
   
   # Run your training command, then detach with Ctrl+A, then D
   # Reattach later with: screen -r training
   ```
7. **Upload Dataset**: Use Jupyter file browser or `scp`/`rsync` to upload your dataset to the instance
8. **Download Results**: Use Jupyter file browser or `scp` to download training results before instance expires

## Troubleshooting

- **CUDA Out of Memory**: Reduce `--batch` size or use `--batch-gpu` to limit per-GPU batch size
- **Dataset Not Found**: Make sure the `--data` path is correct and accessible. Use absolute paths in Jupyter terminal
- **CUDA Not Available**: Verify CUDA is installed and PyTorch can detect it:
  ```bash
  python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA version: {torch.version.cuda if torch.cuda.is_available() else \"N/A\"}')"
  ```
- **Venv Not Activated**: Make sure you see `(.venv)` in your prompt. If not, run `source .venv/bin/activate`
- **Permission Denied**: Make scripts executable with `chmod +x setup_venv.sh`
- **Connection Lost**: Use `screen` or `tmux` to keep training running if you disconnect
- **Out of Disk Space**: Clean up old training runs or use `--outdir` to save to a different location with more space
