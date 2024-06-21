import random
import json
import uuid

from pydantic import BaseModel


class Item(BaseModel):
    id: str
    name: str
    description: str = None
    price: float
    tax: float = None


adjectives = ["Amazing", "Wonderful", "Spectacular", "Fantastic", "Incredible"]
nouns = ["Gadget", "Tool", "Item", "Device", "Instrument"]
verbs = ["Improves", "Boosts", "Enhances", "Revolutionizes", "Transforms"]
domains = ["Efficiency", "Performance", "Productivity", "Workflow", "Operations"]

items = []

for _ in range(10000):
    name = f"{random.choice(adjectives)} {random.choice(nouns)} {_}"
    description = f"{random.choice(verbs)} your {random.choice(domains)} with item number {_}"
    price = round(random.uniform(1, 100000), 2)
    tax = round(price * 0.10, 2)
    item = Item(id=str(uuid.uuid4()), name=name, description=description, price=price, tax=tax)
    items.append(item.dict())

with open("data.json", "w") as f:
    json.dump(items, f, indent=4)
