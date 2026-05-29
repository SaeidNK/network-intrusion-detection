import os
import json
import joblib
import pandas as pd
from flask import Flask, render_template, request, jsonify
from sklearn.linear_model import LogisticRegression
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report
from sklearn.model_selection import train_test_split
import dash
from dash import html, dcc, Input, Output
import plotly.graph_objects as go
import plotly.express as px

from preprocess import preprocessing
from Train import Train

app = Flask(__name__)

# ── Dash app mounted on /dashboard/ ──────────────────────────────────────────
dash_app = dash.Dash(server=app, url_base_pathname='/dashboard/')

RESULTS_FILE = 'results_cache.json'

def load_results():
    """Load cached model results from disk (populated after training)."""
    if os.path.exists(RESULTS_FILE):
        with open(RESULTS_FILE) as f:
            return json.load(f)
    return {}

dash_app.layout = html.Div(style={'fontFamily': 'Arial, sans-serif', 'padding': '20px'}, children=[
    html.H1('Network Intrusion Detection — Model Dashboard',
            style={'color': '#2c3e50', 'borderBottom': '2px solid #3498db', 'paddingBottom': '10px'}),

    html.Div(id='summary-cards', style={'display': 'flex', 'gap': '20px', 'marginBottom': '30px'}),

    html.Div(style={'display': 'flex', 'gap': '30px'}, children=[
        html.Div(style={'flex': 1}, children=[
            html.H3('Model Accuracy Comparison'),
            dcc.Graph(id='accuracy-chart'),
        ]),
        html.Div(style={'flex': 1}, children=[
            html.H3('Precision / Recall / F1 per Model'),
            dcc.Graph(id='metrics-chart'),
        ]),
    ]),

    dcc.Interval(id='refresh', interval=5000, n_intervals=0),
])

@dash_app.callback(
    [Output('summary-cards', 'children'),
     Output('accuracy-chart', 'figure'),
     Output('metrics-chart', 'figure')],
    Input('refresh', 'n_intervals')
)
def update_dashboard(_):
    results = load_results()

    if not results:
        empty = go.Figure()
        empty.add_annotation(text='No results yet — run training from the home page',
                             xref='paper', yref='paper', x=0.5, y=0.5, showarrow=False)
        return [html.P('Train the models to see results here.')], empty, empty

    models = list(results.keys())
    accuracies = [results[m]['accuracy'] for m in models]
    precisions = [results[m]['precision'] for m in models]
    recalls = [results[m]['recall'] for m in models]
    f1s = [results[m]['f1'] for m in models]

    # Summary cards
    cards = []
    for m, acc in zip(models, accuracies):
        cards.append(html.Div(style={
            'background': '#3498db', 'color': 'white', 'padding': '15px 25px',
            'borderRadius': '8px', 'textAlign': 'center', 'minWidth': '160px'
        }, children=[
            html.H4(m, style={'margin': '0 0 8px 0'}),
            html.H2(f'{acc:.1%}', style={'margin': 0}),
            html.Small('Accuracy')
        ]))

    # Accuracy bar chart
    acc_fig = go.Figure(go.Bar(
        x=models, y=accuracies,
        marker_color=['#3498db', '#2ecc71', '#e74c3c'][:len(models)],
        text=[f'{a:.1%}' for a in accuracies], textposition='outside'
    ))
    acc_fig.update_layout(yaxis=dict(range=[0, 1.1], tickformat='.0%'),
                          plot_bgcolor='white', paper_bgcolor='white',
                          margin=dict(t=20))

    # Grouped metrics chart
    metrics_fig = go.Figure()
    metrics_fig.add_trace(go.Bar(name='Precision', x=models, y=precisions, marker_color='#3498db'))
    metrics_fig.add_trace(go.Bar(name='Recall',    x=models, y=recalls,    marker_color='#2ecc71'))
    metrics_fig.add_trace(go.Bar(name='F1 Score',  x=models, y=f1s,        marker_color='#e74c3c'))
    metrics_fig.update_layout(barmode='group', yaxis=dict(range=[0, 1.1], tickformat='.0%'),
                               plot_bgcolor='white', paper_bgcolor='white',
                               margin=dict(t=20))

    return cards, acc_fig, metrics_fig


# ── Flask routes ──────────────────────────────────────────────────────────────
@app.route('/')
def index():
    return render_template('index.html')


@app.route('/train_model', methods=['POST'])
def train_model():
    dataset_path = request.form.get('dataset', './archive/Train_data.csv')

    if not os.path.exists(dataset_path):
        return render_template('results.html',
                               error=f'Dataset not found: {dataset_path}',
                               results=[])

    df = pd.read_csv(dataset_path)
    preprocessor = preprocessing()

    classifiers = [
        ('Logistic Regression', LogisticRegression(max_iter=500)),
        ('Decision Tree',       DecisionTreeClassifier()),
        ('Random Forest',       RandomForestClassifier(n_estimators=100)),
    ]

    results = {}
    html_tables = []

    for name, clf in classifiers:
        html_table = Train(df, preprocessor, clf)
        html_tables.append({'name': name, 'table': html_table})

        # Load the saved model and compute summary metrics
        model_file_map = {
            'Logistic Regression': 'model_LogisticRegression.pkl',
            'Decision Tree':       'model_DecisionTree.pkl',
            'Random Forest':       'model_RandomForest.pkl',
        }
        model_path = model_file_map.get(name)
        if model_path and os.path.exists(model_path):
            loaded = joblib.load(model_path)
            target = 'class'
            X = df.drop(columns=[target])
            y = df[target]
            _, X_test, _, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
            y_pred = loaded.predict(X_test)
            report = classification_report(y_test, y_pred, output_dict=True)
            wa = report.get('weighted avg', {})
            results[name] = {
                'accuracy':  accuracy_score(y_test, y_pred),
                'precision': wa.get('precision', 0),
                'recall':    wa.get('recall', 0),
                'f1':        wa.get('f1-score', 0),
            }

    # Cache results for the dashboard
    with open(RESULTS_FILE, 'w') as f:
        json.dump(results, f)

    return render_template('results.html', results=html_tables, error=None)


@app.route('/api/results')
def api_results():
    """JSON endpoint — useful for external monitoring or integration."""
    return jsonify(load_results())


if __name__ == '__main__':
    app.run(debug=True)
