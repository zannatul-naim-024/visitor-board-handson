export AWS_ACCESS_KEY_ID=local
export AWS_SECRET_ACCESS_KEY=local
export AWS_DEFAULT_REGION=us-east-1
aws dynamodb list-tables --endpoint-url http://localhost:8000
aws dynamodb scan --table-name workshop_messages --endpoint-url http://localhost:8000



sudo dnf install -y git
git clone https://github.com/zannatul-naim-024/visitor-board-handson.git


python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
