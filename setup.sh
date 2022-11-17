# make sure rust compiler is installed (needed for huggingface transformers lib)
curl —proto '=https' —tlsv1.2 -sSf 'https://sh.rustup.rs' '(https://sh.rustup.rs/)'| sh
source "$HOME/.cargo/env"

# setup and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate*

# install dependencies inside virtual environment
pip install --upgrade pip
pip install -r requirements.txt

