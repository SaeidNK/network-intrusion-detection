# Network Intrusion Detection System

![CI](https://github.com/SaeidNK/network-intrusion-detection/actions/workflows/ci.yml/badge.svg)
![Python](https://img.shields.io/badge/python-3.11-blue)
![Flask](https://img.shields.io/badge/flask-2.3-lightgrey)
![scikit-learn](https://img.shields.io/badge/scikit--learn-1.3-orange)
![Terraform](https://img.shields.io/badge/terraform-1.3+-purple)
![AWS](https://img.shields.io/badge/AWS-eu--west--2-orange)

A Python-based Network Intrusion Detection System (NIDS) that trains and compares multiple ML classifiers on the KDD Cup 1999 dataset, with a Flask web interface for triggering training and a live Plotly/Dash dashboard for visualising model performance.

AWS infrastructure is provisioned using Terraform — the app deploys to EC2 with trained models stored in S3.

Built as the practical component of my MSc in Advanced Computer Networks at Birmingham City University.

---

## 🎯 What It Does

- Trains three classifiers (Logistic Regression, Decision Tree, Random Forest) on labelled network traffic data
- Preprocesses features: one-hot encoding for categorical fields (`protocol_type`, `service`, `flag`), standard scaling for numerical fields (`src_bytes`, `dst_bytes`)
- Saves each trained model as a `.pkl` file for reuse — uploaded to S3 for persistence across deployments
- Displays per-model accuracy, precision, recall, and F1 scores in a live Dash dashboard
- Exposes a `/api/results` JSON endpoint for integration with external monitoring tools

---

## 🏗️ Application Architecture

```
┌─────────────────────┐
│  KDD Cup Dataset    │  Train_data.csv (~125k records, 41 features)
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│   preprocess.py     │  OneHotEncoder (categorical) + StandardScaler (numerical)
└────────┬────────────┘
         │
         ▼
┌─────────────────────┐
│     Train.py        │  sklearn Pipeline → fit → classification_report → save .pkl
│  3 classifiers:     │
│  · LogisticRegress  │
│  · DecisionTree     │
│  · RandomForest     │
└────────┬────────────┘
         │
         ▼
┌──────────────────────────────────────────────┐
│              Flask app (app.py)              │
│  /              → trigger training via form  │
│  /train_model   → runs Train.py, caches JSON │
│  /dashboard/    → Plotly/Dash live charts    │
│  /api/results   → JSON metrics endpoint      │
└──────────────────────────────────────────────┘
```

---

## ☁️ AWS Infrastructure (Terraform)

The application runs on AWS, provisioned entirely with Terraform. Infrastructure is defined as code in the `terraform/` directory.

### Architecture

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
VPC (10.0.0.0/16)
    │
    ├── Public Subnet (10.0.1.0/24)  ← eu-west-2a
    │       │
    │       ├── Security Group (port 22 SSH, port 5000 Flask)
    │       │
    │       └── EC2 t3.micro
    │               │ IAM Role (least-privilege)
    │               ▼
    │           S3 Bucket
    │           └── nid.pkl, decision_tree.pkl, random_forest.pkl
    │
    └── Private Subnet (10.0.2.0/24) ← eu-west-2b (reserved)
```

### What Terraform Provisions

| Resource | Details |
|---|---|
| VPC | `10.0.0.0/16`, DNS enabled |
| Public Subnet | `10.0.1.0/24`, EC2 lives here |
| Private Subnet | `10.0.2.0/24`, reserved for future use |
| Internet Gateway | Outbound internet access for public subnet |
| Route Table | Routes public subnet traffic via IGW |
| Security Group | Inbound: SSH (22), Flask (5000). Outbound: all |
| EC2 (t3.micro) | Amazon Linux 2023, encrypted root volume, pulls repo on boot |
| IAM Role | Least-privilege: EC2 can only access this project's S3 bucket |
| S3 Bucket | Model artifact storage, versioning enabled, public access blocked |

### Security Design Decisions

- **Encrypted EBS volume** — root volume encrypted at rest
- **IAM least-privilege** — EC2 role scoped to this project's S3 bucket only; no hardcoded AWS credentials on the instance
- **S3 public access blocked** — model files are never publicly accessible
- **S3 versioning** — allows rollback to previous model versions
- **SSH restricted by CIDR** — configurable via `terraform.tfvars`; default is your IP only

### Deploy

```bash
cd terraform/

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit: set your key_pair_name and allowed_ssh_cidr

terraform init
terraform plan
terraform apply
```

After apply, Terraform outputs:

```
app_url       = "http://<ec2_public_ip>:5000"
dashboard_url = "http://<ec2_public_ip>:5000/dashboard/"
s3_bucket_name = "nid-model-artifacts-dev"
```

Full deployment documentation: [`terraform/README.md`](terraform/README.md)

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Language | Python 3.11 |
| ML | scikit-learn (LogisticRegression, DecisionTree, RandomForest) |
| Preprocessing | OneHotEncoder, StandardScaler, ColumnTransformer, Pipeline |
| Web framework | Flask 2.3 |
| Dashboard | Dash 2.14 + Plotly |
| Data | pandas |
| Model persistence | joblib |
| Dataset | KDD Cup 1999 (network intrusion benchmark) |
| Infrastructure | Terraform >= 1.3, AWS (eu-west-2) |
| Cloud services | EC2, VPC, S3, IAM |
| CI | GitHub Actions |

---

## 🚀 Getting Started (Local)

### Prerequisites
- Python 3.8+

### Installation

```bash
git clone https://github.com/SaeidNK/network-intrusion-detection.git
cd network-intrusion-detection
pip install -r requirements.txt
```

### Dataset

Download the KDD Cup 1999 dataset and place `Train_data.csv` inside an `archive/` folder:

```
network-intrusion-detection/
└── archive/
    └── Train_data.csv
```

Dataset source: [Kaggle — KDD Cup 1999](https://www.kaggle.com/datasets/galaxyh/kdd-cup-1999-data)

### Run

```bash
python app.py
```

Then open your browser:

| URL | Purpose |
|---|---|
| `http://localhost:5000` | Home — trigger model training |
| `http://localhost:5000/dashboard/` | Live accuracy & metrics dashboard |
| `http://localhost:5000/api/results` | JSON metrics endpoint |

---

## 📊 Model Performance (KDD Cup 1999)

| Model | Accuracy | Precision | Recall | F1 |
|---|---|---|---|---|
| Logistic Regression | ~93% | ~93% | ~93% | ~93% |
| Decision Tree | ~99% | ~99% | ~99% | ~99% |
| Random Forest | ~99% | ~99% | ~99% | ~99% |

*Results on a 80/20 train-test split, `random_state=42`.*

---

## 📁 File Structure

```
├── app.py              # Flask app + Dash dashboard
├── NID.py              # Standalone training script (all classifiers)
├── Train.py            # Training function used by app.py
├── preprocess.py       # Feature preprocessing pipeline
├── generateData.py     # Synthetic data generator for testing
├── requirements.txt    # Python dependencies
├── templates/
│   ├── index.html      # Training trigger UI
│   └── results.html    # Results display
├── static/             # CSS assets
├── archive/            # Dataset folder (not committed — see above)
└── terraform/          # AWS infrastructure as code
    ├── main.tf         # VPC, EC2, S3, IAM, security groups
    ├── variables.tf    # All configurable values
    ├── outputs.tf      # Post-deploy: app URL, IP, S3 bucket name
    ├── terraform.tfvars.example
    ├── .gitignore      # Excludes state files and tfvars
    └── README.md       # Full deployment instructions
```

---

## 🎓 What I Learned

- Building end-to-end ML pipelines with scikit-learn's `Pipeline` and `ColumnTransformer`
- The trade-offs between signature-based and anomaly/ML-based intrusion detection
- Integrating a Dash dashboard inside a Flask app for live observability
- Designing classification reporting that surfaces precision/recall/F1 clearly, not just accuracy
- How dataset imbalance in KDD Cup affects per-class metrics vs weighted averages
- Provisioning secure AWS infrastructure with Terraform: VPC design, IAM least-privilege, encrypted storage

---

## 🔮 Future Improvements

- [ ] Dockerise the app for portable deployment
- [ ] AWS CloudWatch integration for centralised log monitoring and alerting
- [ ] Add a confusion matrix visualisation to the dashboard
- [ ] Support uploading custom `.csv` datasets via the web UI
- [ ] GitHub Actions: auto-train on push and publish metrics as a workflow summary

---

## 📚 Background

This project was built as the practical component of my MSc in Advanced Computer Networks at Birmingham City University, drawing on the Network Automation and Ethical Hacking modules. It demonstrates an ML-based approach to network security — combining a full ML training pipeline, a live web dashboard, and production-ready AWS infrastructure provisioned with Terraform.

---

**Author:** Sam Nakhjavan · [LinkedIn](https://www.linkedin.com/in/sam-nakhjavan/) · [GitHub](https://github.com/SaeidNK)
