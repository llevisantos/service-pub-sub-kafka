print('----- Initial configuration database -----');

db.getSiblingDB('engdevdb');
db.createCollection('mass');

print('----- Insert initial data -----');

db.getCollection('mass')([
{
    "fieldKey": "bf9aa",
    "data": [
    {
        "personName": "Iron Man",
        "id": "001001",
        "status": "live"

    }
    ]
}
])