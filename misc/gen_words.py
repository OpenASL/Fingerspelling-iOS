import json
import urllib.request
import pathlib

HERE = pathlib.Path(__file__).parent
OUTPUT = HERE.parent / "Fingerspelling" / "Words.swift"

WORDS_URL = "https://raw.githubusercontent.com/derekchuank/high-frequency-vocabulary/master/10k.txt"
NAUGHTY_WORDS_URL = "https://raw.githubusercontent.com/sloria/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words/en/en"
TEMPLATE = """
/**
 GENERATED FILE--DO NOT EDIT
 */
public let Words: [String] = {words}
"""


def fetch(url):
    req = urllib.request.Request(url)
    return urllib.request.urlopen(req)


def main():
    print("Fetching words lists...")
    naughty_resp = fetch(NAUGHTY_WORDS_URL)
    naughty_words = set()
    for line in naughty_resp.readlines():
        word = line.decode("utf-8").lower().strip()
        # very naive inflection, but fine for out purposes
        plural, past, gerund = f"{word}s", f"{word}ed", f"{word}ing"
        naughty_words |= {word, plural, past, gerund}

    words_resp = fetch(WORDS_URL)
    words = []
    for line in words_resp.readlines():
        word = line.decode("utf-8").lower().strip()
        if len(word) > 2 and word not in naughty_words:
            words.append(word)

    print(f"Writing to {OUTPUT}...")
    content = TEMPLATE.format(words=json.dumps(words))
    with OUTPUT.open("w") as out_fp:
        out_fp.write(content)
    print("Done.")


if __name__ == "__main__":
    main()
