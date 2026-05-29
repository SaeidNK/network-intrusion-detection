# Network Intrusion Detection System

![CI](https://github.com/SaeidNK/network-intrusion-detection/actions/workflows/ci.yml/badge.svg)
![Python](https://img.shields.io/badge/python-3.11-blue)
![Flask](https://img.shields.io/badge/flask-2.3-lightgrey)
![scikit-learn](https://img.shields.io/badge/scikit--learn-1.3-orange)

A Python-based Network Intrusion Detection System (NIDS) that trains and compares multiple ML classifiers on the KDD Cup 1999 dataset, with a Flask web interface for triggering training and a live Plotly/Dash dashboard for visualising model performance.

Built as the practical component of my MSc in Advanced Computer Networks at Birmingham City University.

---

## 🎯 What It Does

- Trains three classifiers (Logistic Regression, Decision Tree, Random Forest) on labelled network traffic data
- Preprocesses features: one-hot encoding for categorical fields (`protocol_type`, `service`, `flag`), standard scaling for numerical fields (`src_bytes`, `dst_bytes`)
- Saves each trained model as a `.pkl` file for reuse
- Displays per-model accuracy, precision, recall, and F1 scores in a live Dash dashboard
- Exposes a `/api/results` JSON endpoint for integration with external monitoring tools

---

## 🏗️ Architecture

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

---

## 🚀 Getting Started

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
└── archive/            # Dataset folder (not committed — see above)
```

---

## 🎓 What I Learned

- Building end-to-end ML pipelines with scikit-learn's `Pipeline` and `ColumnTransformer`
- The trade-offs between signature-based and anomaly/ML-based intrusion detection
- Integrating a Dash dashboard inside a Flask app for live observability
- Designing classification reporting that surfaces precision/recall/F1 clearly, not just accuracy
- How dataset imbalance in KDD Cup affects per-class metrics vs weighted averages

---

## 🔮 Future Improvements

- [ ] Dockerise the app for portable deployment
- [ ] AWS CloudWatch integration for centralised alerting
- [ ] Add a confusion matrix visualisation to the dashboard
- [ ] Support uploading custom `.csv` datasets via the web UI
- [ ] GitHub Actions: auto-train on push and publish metrics as a workflow summary

---

## 📚 Background

This project was built as the practical component of my MSc in Advanced Computer Networks at Birmingham City University, drawing on the Network Automation and Ethical Hacking modules. It demonstrates an ML-based approach to network security, with a web interface that makes results accessible to non-technical stakeholders.

---

**Author:** Sam Nakhjavan · [LinkedIn](https://www.linkedin.com/in/sam-nakhjavan/) · [GitHub](https://github.com/SaeidNK)
