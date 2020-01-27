import jinja2


env = jinja2.Environment(
    loader=jinja2.PackageLoader('abl', 'templates'),
)

box = env.get_template("abl.box.j2")
size = env.get_template("SIZE.j2")
