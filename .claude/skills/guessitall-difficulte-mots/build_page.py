"""Injecte data.json dans template.html. Usage : python3 build_page.py <data.json> <sortie.html>"""
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
tpl = open(os.path.join(here, "template.html")).read()
data = open(sys.argv[1]).read().replace("</", "<\\/")
open(sys.argv[2], "w").write(tpl.replace("__DATA__", data))
