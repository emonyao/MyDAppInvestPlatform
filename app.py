from flask import Flask,render_template,request, redirect, url_for, jsonify
from models import db, Project
from datetime import datetime
from flask import g
import os
from flask import send_from_directory



app=Flask(__name__)

# 配置 SQLite 数据库
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///projects.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# 绑定数据库
db.init_app(app)

# 在应用启动前创建数据库
@app.before_request
def create_tables():
    if not hasattr(g, 'tables_created'):
        # db.create_all()  # 确保表格在第一次请求时创建
        g.tables_created = True


@app.route('/',methods=["get","post"])
def index():
    return render_template('index.html')

@app.route('/store_money',methods=["get","post"])
def store_money():
    return render_template('store_money.html')

@app.route('/transfer_money',methods=["get","post"])
def transfer_money():
    return render_template('transfer_money.html')

@app.route('/investment',methods=["get","post"])
def investment():
    return render_template('investment.html')

# Store project details into the database
@app.route('/add_project', methods=['POST'])
def add_project():
    name = request.json['projectName']
    target_amount = float(request.json['targetAmount'])
    deadline_str = request.json['deadline']
    creator = request.json['creator']

    deadline = datetime.strptime(deadline_str, '%Y-%m-%dT%H:%M')

    new_project = Project(name=name, target_amount=target_amount, deadline=deadline, creator=creator)
    db.session.add(new_project)
    db.session.commit()

    return jsonify({'status': 'Project added successfully!'})

# Retrieve all projects from the database
@app.route('/get_projects', methods=['GET'])
def get_projects():
    projects = Project.query.all()
    project_list = [
        {
            'id': project.id,
            'name': project.name,
            'target_amount': project.target_amount,
            'current_amount': project.current_amount,
            'deadline': project.deadline.strftime('%Y-%m-%d %H:%M:%S'),
            'creator': project.creator
        }
        for project in projects
    ]
    return jsonify(project_list)


@app.route('/favicon.ico')
def favicon():
    return send_from_directory(os.path.join(app.root_path, 'static'),
                               'favicon.ico', mimetype='image/vnd.microsoft.icon')

if __name__=='__main__':
    app.run()