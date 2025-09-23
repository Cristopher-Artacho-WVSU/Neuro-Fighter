import marimo

__generated_with = "0.16.0"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo
    import tensorflow as tf
    import keras
    import pandas as pd
    return keras, pd, tf


@app.cell
def _():
    with open("./training.txt") as f:
        training_contents = f.read()
    print(training_contents)
    return (training_contents,)


@app.cell
def _(training_contents):
    import re
    from pprint import pprint
    timestamps = re.findall(r"Timestamp:\s*([0-9T:\-+\.Z]+)", training_contents)
    generated_scripts = re.findall(r"^\[\s*\n(.*?)\n\]\s*$", training_contents, re.DOTALL | re.MULTILINE)
    parameters = re.findall(r"--- Parameters: (\{.*?\})\s*---", training_contents)
    rules_executed = re.findall(r'\[\d+(?:,\d+)*\]', training_contents)
    return generated_scripts, parameters, rules_executed


@app.cell
def _(generated_scripts, parameters, rules_executed):
    import json
    generated_scripts_json = [json.loads('[' + script + ']') for script in generated_scripts]
    parameters_json = [json.loads(parameter) for parameter in parameters]
    rules_executed_json = [json.loads(rules) for rules in rules_executed]
    return generated_scripts_json, parameters_json


@app.cell
def _(generated_scripts_json, parameters_json, pd):
    relevant_inputs = [[{"ruleID": rule["ruleID"], "weight": rule["weight"], "wasUsed": rule["wasUsed"]} for rule in step] for step in generated_scripts_json]
    relevant_inputs = [
        {**d, "t": t}
        for t, row in enumerate(relevant_inputs)
        for d in row
    ]
    relevant_inputs_df = pd.DataFrame(relevant_inputs)
    relevant_inputs_df = relevant_inputs_df.pivot(index='t', columns='ruleID', values=["weight", "wasUsed"])
    relevant_inputs_df = pd.concat([relevant_inputs_df, pd.DataFrame(parameters_json)], axis=1)
    return (relevant_inputs_df,)


@app.cell
def _(keras, relevant_inputs_df):
    from keras import models, layers

    keras.backend.clear_session()

    model = models.Sequential([
        layers.Input(shape=(None, relevant_inputs_df.shape[1]), name='inputs'),
        layers.LSTM(32, name='lstm'),
        layers.Dense(relevant_inputs_df.shape[1], name='output')
    ])

    optimizer = keras.optimizers.RMSprop(learning_rate=0.1, rho=0.9)
    model.compile(optimizer='adam', loss='mse', metrics=['mse', 'mae'])
    return (model,)


@app.cell
def _(model, relevant_inputs_df):
    import numpy as np

    X = relevant_inputs_df.to_numpy(np.float32)
    X = np.expand_dims(X, axis=0)

    model.fit(np.array([x[:-1] for x in X]), np.array([x[1:] for x in X]), epochs=5)
    return


@app.cell
def _(model, tf):
    @tf.function(input_signature=[
        tf.TensorSpec([None, 2, 14], tf.float32, name="input")
    ])
    def serving_fn(x):
        return {"predictions": model(x, training=False)}

    model.export("nds1", signatures={"serving_default": serving_fn})
    return


if __name__ == "__main__":
    app.run()
