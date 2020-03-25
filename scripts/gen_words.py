import json
import pathlib
import sqlite3
import urllib.request

HERE = pathlib.Path(__file__).parent
OUTPUT = HERE.parent / "Fingerspelling" / "Data" / "Words.swift"
BLACKLIST = HERE / "blacklist.db"

WORDS_URL = "https://raw.githubusercontent.com/derekchuank/high-frequency-vocabulary/master/10k.txt"
NAUGHTY_WORDS_URL = "https://raw.githubusercontent.com/sloria/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words/en/en"
TEMPLATE = """
/**
 GENERATED FILE--DO NOT EDIT
 */
public var AllWords: [String] = {words}
public var Words: [String] = AllWords
"""


def fetch(url):
    req = urllib.request.Request(url)
    return urllib.request.urlopen(req)


def main():
    con = sqlite3.connect("scripts/blacklist.db")

    blacklisted_words = {
        row[0] for row in con.execute("select word from blacklisted_words")
    }
    print("Fetching words lists...")
    naughty_resp = fetch(NAUGHTY_WORDS_URL)
    for line in naughty_resp.readlines():
        word = line.decode("utf-8").lower().strip()
        # very naive inflection, but fine for out purposes
        plural, past, gerund = f"{word}s", f"{word}ed", f"{word}ing"
        blacklisted_words |= {word, plural, past, gerund}

    words_resp = fetch(WORDS_URL)
    words = []
    for line in words_resp.readlines():
        word = line.decode("utf-8").lower().strip()
        if len(word) > 2 and word not in blacklisted_words:
            words.append(word)

    print(f"Writing to {OUTPUT}...")
    content = TEMPLATE.format(words=json.dumps(words))
    with OUTPUT.open("w") as out_fp:
        out_fp.write(content)
    print("Done.")


if __name__ == "__main__":
    main()
