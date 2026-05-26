# Network Intrusion Detection System

A Python-based Network Intrusion Detection System (NIDS) with a web-based dashboard for real-time traffic monitoring and threat alerting. Built as part of my MSc in Advanced Computer Networks.

## 🎯 What It Does

- Captures and analyzes network packets in real-time
- Detects suspicious traffic patterns (e.g., port scans, unusual connection rates)
- Displays alerts and traffic statistics through a Flask web interface
- Logs all detected events for later review

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│  Network Layer  │───▶│  Packet Analyzer │───▶│  Detection Rules│
│   (Scapy/PCAP)  │    │     (Python)     │    │      Engine     │
└─────────────────┘    └──────────────────┘    └────────┬────────┘
                                                        │
                       ┌────────────────────────────────▼─┐
                       │   Flask Web Dashboard            │
                       │   - Live alerts                  │
                       │   - Traffic stats                │
                       │   - Historical logs              │
                       └──────────────────────────────────┘
```

*(Replace this with a draw.io / Excalidraw diagram once you make one)*

## 🛠️ Tech Stack

- **Language:** Python 3.x
- **Packet Capture:** [Scapy / PyShark — whichever you used]
- **Web Framework:** Flask
- **Frontend:** HTML / CSS / [JS framework if any]
- **Storage:** [SQLite / files / whatever you used]

## 🚀 Getting Started

### Prerequisites
- Python 3.8+
- Root/admin privileges (required for packet capture)

### Installation
```bash
git clone https://github.com/SaeidNK/network-intrusion-detection.git
cd network-intrusion-detection
pip install -r requirements.txt
```

### Running
```bash
sudo python app.py
```
Open `http://localhost:5000` in your browser.

## 📸 Screenshots

[ADD A SCREENSHOT OF THE DASHBOARD HERE — this is the single most important thing in your README]

## 🎓 What I Learned

- Deep dive into TCP/IP protocol analysis at the packet level
- Building lightweight detection rule engines
- Designing observability dashboards that surface signal without noise
- The trade-offs between signature-based vs. anomaly-based detection

## 🔮 Future Improvements

- [ ] Integration with AWS CloudWatch for centralized alerting
- [ ] Containerization with Docker
- [ ] Machine learning-based anomaly detection
- [ ] Multi-interface support

## 📚 Background

This project was developed as part of my MSc in Advanced Computer Networks at Birmingham City University, with input from the Ethical Hacking module. It applies network security principles in a practical, working system.

---

**Author:** Sam Nakhjavan ([LinkedIn](https://www.linkedin.com/in/sam-nakhjavan/))
