# Deploy / Server Workflow — FaSi_VIZ

## Pull latest from server
```bash
ssh -F NUL -m hmac-sha2-512 skeledzi@skeledzi.ssh.cloud.hostpoint.ch
cd ~/projects/FaSi_VIZ
git pull origin dev
```

## First-time setup on server
```bash
git clone git@github.com:FaSiMaster/FaSi_VIZ.git ~/projects/FaSi_VIZ
cd ~/projects/FaSi_VIZ
git checkout dev
pip install -e .
```

## Run on server
```bash
python -m pytest tests/
```

## Note
Pure Python package — runs on Linux server without issues.
No ArcPy dependency.
