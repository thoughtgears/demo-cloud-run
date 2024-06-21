from flask import Flask, render_template, request, redirect, url_for, jsonify
import requests
import os

app = Flask(__name__)

discovery_url = os.getenv("DISCOVERY_URL")
if discovery_url:
    resp = requests.get(url=f"{discovery_url}/services/backend").json()
    backend_url = resp["url"]
else:
    backend_url = os.getenv("BACKEND_URL")


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/items", methods=["GET"])
def get_items():
    page = request.args.get("page", 1, type=int)
    per_page = request.args.get("per_page", 20, type=int)
    skip = (page - 1) * per_page
    response = requests.get(f"{backend_url}/items?skip={skip}&limit={per_page}")
    items = response.json()
    return jsonify(items)


@app.route("/items/<item_id>")
def item_detail(item_id):
    response = requests.get(f"{backend_url}/items/{item_id}")
    item = response.json()
    return render_template("item.html", item=item)


@app.route("/items/create", methods=["GET", "POST"])
def create_item():
    if request.method == "POST":
        name = request.form["name"]
        description = request.form["description"]
        price = request.form["price"]
        tax = request.form["tax"]
        item_data = {"name": name, "description": description, "price": float(price), "tax": float(tax)}
        response = requests.post(f"{backend_url}/items", json=item_data)
        if response.status_code == 200:
            return redirect(url_for("index"))
        else:
            return "Failed to create item", 400
    return render_template("create_item.html")


@app.route("/items/<item_id>/edit", methods=["GET", "POST"])
def edit_item(item_id):
    if request.method == "POST":
        name = request.form["name"]
        description = request.form["description"]
        price = request.form["price"]
        tax = request.form["tax"]
        item_data = {"name": name, "description": description, "price": float(price), "tax": float(tax)}
        response = requests.put(f"{backend_url}/items/{item_id}", json=item_data)
        if response.status_code == 200:
            return redirect(url_for("item_detail", item_id=item_id))
        else:
            return "Failed to update item", 400

    response = requests.get(f"{backend_url}/{item_id}")
    item = response.json()
    return render_template("edit_item.html", item=item)


@app.route("/items/<item_id>/delete", methods=["POST"])
def delete_item(item_id):
    response = requests.delete(f"{backend_url}/items/{item_id}")
    if response.status_code == 200:
        return redirect(url_for("index"))
    else:
        return "Failed to delete item", 400


if __name__ == "__main__":
    app.run(debug=True, port=8080, host="0.0.0.0")
