# make sure rust compiler is installed (needed for huggingface transformers lib)
curl —proto '=https' —tlsv1.2 -sSf 'https://sh.rustup.rs' '(https://sh.rustup.rs/)'| sh
source "$HOME/.cargo/env"

# download huggingface question answering model artifacts
mkdir $PWD/model_endpoint/runtime/serving_api/custom_lambda_utils/model_artifacts
curl -L https://huggingface.co/distilbert-base-cased-distilled-squad/resolve/main/pytorch_model.bin -o $PWD/model_endpoint/runtime/serving_api/custom_lambda_utils/model_artifacts/pytorch_model.bin
curl https://huggingface.co/distilbert-base-cased-distilled-squad/resolve/main/config.json -o $PWD/model_endpoint/runtime/serving_api/custom_lambda_utils/model_artifacts/config.json
curl https://huggingface.co/distilbert-base-cased-distilled-squad/resolve/main/tokenizer.json -o $PWD/model_endpoint/runtime/serving_api/custom_lambda_utils/model_artifacts/tokenizer.json
curl https://huggingface.co/distilbert-base-cased-distilled-squad/resolve/main/tokenizer_config.json -o $PWD/model_endpoint/runtime/serving_api/custom_lambda_utils/model_artifacts/tokenizer_config.json
curl https://huggingface.co/distilbert-base-cased-distilled-squad/resolve/main/vocab.txt -o $PWD/model_endpoint/runtime/serving_api/custom_lambda_utils/model_artifacts/vocab.txt

# setup and activate virtual environment
python3 -m venv .venv
source .venv/bin/activate*

# install dependencies inside virtual environment
pip install --upgrade pip
pip install -r requirements.txt

