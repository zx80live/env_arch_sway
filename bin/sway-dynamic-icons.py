#!/usr/bin/python

import re

import i3ipc

# TODO move to config
ICO_APP_ID = {
    '(?i)firefox': {'ico': '', 'color': '#f39c12'},
    '(?i)alacritty|kitty': {'ico': '', 'color': '#27ae60'},
    '(?i)telegramdesktop': {'ico': '', 'color': '#3498db'},
    '(?i)libreoffice-writer': {'ico': '', 'color': '#bde5f8'},
    '(?i)libreoffice-calc': {'ico': '', 'color': '#a3e4d7'},
    '(?i)gedit': {'ico': '', 'color': '#bde5f8'},
    '(?i)simple-scan': {'ico': 'ﮩ', 'color': '#bde5f8'},
    '(?i)org.gajim.Gajim': {'ico': '', 'color': '#bde5f8'}
}

ICO_TITLE = {
    '(?i)firefox private browsing': {'ico': '', 'color': '#a569bd'},
    '(?i)gmail': {'ico': '', 'color': '#5dade2'},
    '(?i)stack overflow': {'ico': '', 'color': '#eb984e'},
    '(?i)google search': {'ico': '', 'color': '#a6acaf'},
    '(?i)youtube': {'ico': '輸', 'color': '#ec7063'},
    '(?i)htop': {'ico': '', 'color': '#27ae60'},
    '(?i)bpytop': {'ico': '', 'color': '#a569bd'},
    '(?i)ranger|lf\:': {'ico': '', 'color': '#61abda'},
    '(?i)vim': {'ico': '', 'color': '#239b56'},
    '(?i)watch_lsblk': {'ico': '', 'color': 'green'},
    '\/work': {'ico': '', 'color': '#bde5f8'},
    '\.config': {'ico': '', 'color': 'green'}
}

ICO_INSTANCE = {
    '(?i)gimp': {'ico': '', 'color': '#ba4a00'}
}

ICO_CLASS = {
    '(?i)jetbrains-idea-ce': {'ico': '', 'color': '#3498db'},
    '(?i)jetbrains-pycharm-ce': {'ico': '', 'color': '#9cea66'},
}

ICO_DEFAULT = {'ico': 'ﬓ', 'color': 'white'}

WS_DELIM = " <span foreground='#2e2e2e'>│</span>"


def matched_key(s, d):
    for k in d:
        pattern = str(k)
        string = str(s)
        m = re.search(pattern, string)
        if m is not None:
            ico = d[k]
            return ico
    return None


def find_ico(evt_con):
    def by_title():
        return matched_key(evt_con['name'], ICO_TITLE)

    def by_app_id():
        return matched_key(evt_con.get('app_id'), ICO_APP_ID)

    def by_class():
        key = evt_con.get('window_properties', {}).get('class') or evt_con.get('window_class')
        return matched_key(key, ICO_CLASS)

    def by_inst():
        key = evt_con.get('window_properties', {}).get('instance') or evt_con.get('window_instance')
        return matched_key(key, ICO_INSTANCE)

    ico = by_title() or \
          by_app_id() or \
          by_class() or \
          by_inst() or \
          ICO_DEFAULT

    return ico


def mod_container(ipc, e):
    evt_con = vars(e)['ipc_data']['container']
    evt_con_id = evt_con['id']
    evt_title = evt_con['name']
    evt_con_marks = evt_con['marks']

    def make_title(ico, name):
        return '<span foreground="%s">%s </span> %s' % (ico['color'], ico['ico'], name)

    new_title = make_title(find_ico(evt_con), evt_title)

    # update container icon
    if not evt_con_marks or new_title not in evt_con_marks:
        ipc.command('[con_id=%i] mark --replace %s' % (evt_con_id, new_title))
        ipc.command('[con_id=%i] title_format %s' % (evt_con_id, new_title))

    # update workspaces icons
    # TODO optimize (subscribe event, add marks to ws, etc)

    for ws in ipc.get_tree().workspaces():
        ws_icons = list()
        for app in ws:
            if app.pid is not None:
              ws_icons.append(find_ico(vars(app)))

        # ico_titles = set(map(lambda i: make_title(i, ""), ws_icons)) # TODO fix colors
        ico_titles = set(map(lambda i: i['ico'] + ' ', ws_icons))
        ws_new_title = str(ws.num) + WS_DELIM + ' '.join(ico_titles)
        ipc.command('rename workspace "%s" to "%s"' % (ws.name, ws_new_title))


if __name__ == "__main__":

    def window_event_handler(ipc, e):
        if e.change in ["new", "close", "move", "title"]:
            mod_container(ipc, e)

    ipc = i3ipc.Connection()
    ipc.on("window", window_event_handler)
    ipc.main()
