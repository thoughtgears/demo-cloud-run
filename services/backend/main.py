from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import json
import uuid
from typing import List, Optional

app = FastAPI()


class Item(BaseModel):
    id: str
    name: str
    description: Optional[str] = None
    price: float
    tax: Optional[float] = None


def read_items():
    with open("data.json", "r") as f:
        return json.load(f)


def write_items(items):
    with open("data.json", "w") as f:
        json.dump(items, f, indent=4)


@app.get("/items", response_model=List[Item])
def get_items(skip: int = 0, limit: int = 10):
    items = read_items()
    return items[skip: skip + limit]


@app.get("/items/{item_id}", response_model=Item)
def get_item(item_id: str):
    items = read_items()
    for item in items:
        if item["id"] == item_id:
            return item
    raise HTTPException(status_code=404, detail="Item not found")


@app.post("/items", response_model=Item)
def create_item(item: Item):
    items = read_items()
    item.id = str(uuid.uuid4())
    items.append(item.dict())
    write_items(items)
    return item


@app.put("/items/{item_id}", response_model=Item)
def update_item(item_id: str, item: Item):
    items = read_items()
    for i, existing_item in enumerate(items):
        if existing_item["id"] == item_id:
            items[i] = item.dict()
            write_items(items)
            return item
    raise HTTPException(status_code=404, detail="Item not found")


@app.delete("/items/{item_id}")
def delete_item(item_id: str):
    items = read_items()
    for i, item in enumerate(items):
        if item["id"] == item_id:
            del items[i]
            write_items(items)
            return {"detail": "Item deleted"}
    raise HTTPException(status_code=404, detail="Item not found")


if __name__ == "__main__":
    import uvicorn

    print("Starting discovery service...")
    uvicorn.run("main:app", host="0.0.0.0", port=8080, reload=True)
