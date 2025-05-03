# This file handles the setup of the Flask app and starts it. 
from app import create_app

app = create_app()

if __name__ == '__main__':
    app.run(debug=True)
