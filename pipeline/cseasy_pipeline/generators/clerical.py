"""Clerical-ability generators for the CSE Subprofessional level.

Clerical items cover the two areas CSC lists for the subtest: filing (names
in alphabetical order, fully computable) and spelling (picking the right
form from a curated list of words and their common misspellings).
"""

from __future__ import annotations

import random
from typing import Callable

from ..builder import computed_question

LEVELS = ("subprofessional",)

GIVEN = [
    "Maria", "Jose", "Ana", "Juan", "Cristina", "Mark", "Liza", "Paolo", "Rhea", "Carlo",
    "Grace", "Ramon", "Elena", "Rodel", "Joy", "Vincent", "Teresa", "Miguel", "Andrea", "Noel",
]
# Single-word surnames only: multi-word ones (Dela Cruz, De Leon) follow
# agency-specific filing rules we can't assume.
SURNAMES = [
    "Santos", "Reyes", "Cruz", "Bautista", "Ocampo", "Garcia", "Mendoza", "Torres", "Castillo",
    "Flores", "Villanueva", "Ramos", "Navarro", "Aquino", "Salazar", "Mercado", "Aguilar",
    "Rivera", "Gonzales", "Lopez", "Pascual", "Domingo", "Soriano", "Valdez", "Manalo", "Cabrera",
]


def _q(rng: random.Random, topic: str, **kwargs) -> dict:
    return computed_question(rng, section="clerical", topic=topic, levels=LEVELS, fmt=str, **kwargs)


def filing_order(rng: random.Random) -> dict:
    while True:
        # Shared surnames force the second and third sort keys to matter.
        surnames = rng.sample(SURNAMES, 3)
        people = {
            (rng.choice(surnames), rng.choice(GIVEN), rng.choice("ABCDEFGHJLMNPRSTV"))
            for _ in range(5)
        }
        if len(people) == 5 and len({p[0] for p in people}) < 5:
            break
    people = list(people)
    rng.shuffle(people)
    filed = sorted(people)
    place = rng.randrange(5)
    label = lambda p: f"{p[0]}, {p[1]} {p[2]}."  # noqa: E731
    ordinals = ["first", "second", "third", "fourth", "fifth"]
    return _q(
        rng, "filing_order",
        stem=(
            "Arrange these names in alphabetical filing order (surname, then first name, then middle initial):\n"
            + "\n".join(label(p) for p in people)
            + f"\nWhich name comes {ordinals[place]}?"
        ),
        answer=label(filed[place]),
        distractors=[label(p) for p in filed if p != filed[place]],
        explanation="Filing order: " + "; ".join(label(p) for p in filed),
        difficulty=2,
    )


# -------------------------------------------------------------------- spelling

# Commonly misspelled words with three misspellings each, in American
# spelling (the government standard). Words with accepted variant spellings
# (judgment/judgement, license/licence, canceled/cancelled) are left out so
# no "misspelling" can be defended as correct.
MISSPELLINGS: dict[str, tuple[str, str, str]] = {
    "accommodate": ("accomodate", "acommodate", "accommadate"),
    "achievement": ("acheivement", "achievment", "achievemant"),
    "acquire": ("aquire", "acquier", "accquire"),
    "accessible": ("accesible", "accessable", "acessible"),
    "allegiance": ("allegience", "alegiance", "allegance"),
    "apparent": ("apparant", "aparent", "apparrent"),
    "argument": ("arguement", "argumant", "arguemant"),
    "beginning": ("begining", "beggining", "beginnig"),
    "believe": ("beleive", "belive", "beleave"),
    "bureaucracy": ("beaurocracy", "bureacracy", "burocracy"),
    "business": ("buisness", "bussiness", "busines"),
    "calendar": ("calender", "calandar", "calander"),
    "category": ("catagory", "catigory", "categorie"),
    "cemetery": ("cemetary", "cematery", "semetery"),
    "colleague": ("collegue", "colleage", "colleauge"),
    "commitment": ("committment", "comitment", "commitmant"),
    "committee": ("comittee", "commitee", "committe"),
    "conscience": ("concience", "conscence", "consciense"),
    "conscientious": ("conscientous", "consciencious", "concientious"),
    "convenience": ("convinience", "conveniance", "convenence"),
    "correspondence": ("correspondance", "corespondence", "correspondense"),
    "definitely": ("definately", "definitly", "defenitely"),
    "desperate": ("desparate", "desperite", "despirate"),
    "dilemma": ("dilemna", "dilema", "dillemma"),
    "disappoint": ("dissapoint", "disapoint", "dissappoint"),
    "discipline": ("dicipline", "disipline", "discipine"),
    "eligible": ("eligable", "elligible", "eligibel"),
    "embarrass": ("embarass", "embaress", "emberrass"),
    "entrepreneur": ("entrepeneur", "entreprenuer", "entrepreneor"),
    "environment": ("enviroment", "environmant", "envirnoment"),
    "equipment": ("equiptment", "equipmant", "equippment"),
    "especially": ("expecially", "especialy", "espescially"),
    "exaggerate": ("exagerate", "exaggarate", "exxagerate"),
    "existence": ("existance", "existense", "exsistence"),
    "experience": ("experiance", "expirience", "experence"),
    "familiar": ("familar", "famillar", "familliar"),
    "February": ("Febuary", "Februray", "Febrary"),
    "fluorescent": ("flourescent", "fluoresent", "fluorecent"),
    "foreign": ("foriegn", "foreing", "forein"),
    "government": ("goverment", "governmant", "govenment"),
    "grammar": ("grammer", "gramar", "grammmar"),
    "guarantee": ("garantee", "guarentee", "gaurantee"),
    "harass": ("harrass", "harras", "haross"),
    "hierarchy": ("heirarchy", "hierachy", "hiearchy"),
    "immediately": ("immediatly", "imediately", "immediatley"),
    "independent": ("independant", "independint", "indipendent"),
    "indispensable": ("indispensible", "indespensable", "indispensabel"),
    "interrupt": ("interupt", "interrput", "enterrupt"),
    "irresistible": ("irresistable", "iresistible", "irrisistible"),
    "knowledge": ("knowlege", "knowlage", "knowledege"),
    "liaison": ("liason", "liasion", "laison"),
    "library": ("libary", "librery", "liberary"),
    "lieutenant": ("leutenant", "lieutenent", "lieutanant"),
    "maintenance": ("maintainance", "maintenence", "maintanance"),
    "manageable": ("managable", "manageble", "menageable"),
    "millennium": ("millenium", "milennium", "millennuim"),
    "miniature": ("miniture", "minature", "miniatur"),
    "mischievous": ("mischievious", "mischevous", "mischeivous"),
    "necessary": ("neccessary", "necessery", "neccesary"),
    "negotiate": ("negociate", "negoshiate", "negotiatte"),
    "noticeable": ("noticable", "noticeble", "notecable"),
    "occasion": ("occassion", "ocasion", "occaision"),
    "occasionally": ("occasionaly", "occassionally", "ocasionally"),
    "occurred": ("occured", "ocurred", "occurrd"),
    "occurrence": ("occurence", "occurrance", "ocurrence"),
    "omission": ("ommission", "omision", "ommision"),
    "parliament": ("parliment", "parlament", "parlaiment"),
    "perseverance": ("perseverence", "perserverance", "persevereance"),
    "personnel": ("personell", "personnell", "presonnel"),
    "possession": ("posession", "possesion", "possessoin"),
    "precede": ("preceed", "presede", "precide"),
    "prejudice": ("predjudice", "prejudise", "prejidice"),
    "privilege": ("privilage", "priviledge", "privelege"),
    "procedure": ("proceedure", "procedue", "procedur"),
    "proceed": ("procede", "proceede", "prossed"),
    "pronunciation": ("pronounciation", "pronunsiation", "pronuncation"),
    "publicly": ("publically", "publicaly", "publicley"),
    "pursue": ("persue", "pursew", "pursoo"),
    "questionnaire": ("questionaire", "questionnair", "questionnare"),
    "receipt": ("reciept", "receit", "recipt"),
    "receive": ("recieve", "receve", "receeve"),
    "recommend": ("reccommend", "recomend", "reccomend"),
    "reference": ("referance", "refference", "referrence"),
    "referred": ("refered", "reffered", "referd"),
    "rehearsal": ("rehersal", "rehearsel", "reahearsal"),
    "relevant": ("relevent", "revelant", "relavant"),
    "restaurant": ("restaraunt", "resturant", "restaurent"),
    "rhythm": ("rythm", "rhythym", "rythem"),
    "schedule": ("schedual", "scedule", "shedule"),
    "secretary": ("secretery", "secertary", "secratary"),
    "separate": ("seperate", "separete", "saparate"),
    "sergeant": ("sargeant", "sergent", "seargent"),
    "similar": ("similiar", "simmilar", "similer"),
    "sincerely": ("sincerly", "sincerley", "sinceerly"),
    "souvenir": ("souvenier", "suvenir", "souveneer"),
    "successful": ("succesful", "successfull", "sucessful"),
    "technique": ("tecnique", "techneque", "techinique"),
    "temperament": ("temperment", "temparament", "tempermant"),
    "tendency": ("tendancy", "tendensy", "tendencey"),
    "threshold": ("threshhold", "treshold", "threshould"),
    "tomorrow": ("tommorow", "tomorow", "tommorrow"),
    "transferred": ("transfered", "tranferred", "transferrd"),
    "truly": ("truely", "truley", "trully"),
    "unanimous": ("unanimus", "unanimouse", "unaminous"),
    "until": ("untill", "untile", "unntil"),
    "vacuum": ("vacume", "vaccum", "vacuume"),
    "vehicle": ("vehical", "vehicel", "vechicle"),
    "vicious": ("viscious", "vicous", "vicioous"),
    "weird": ("wierd", "weerd", "wiered"),
    "withhold": ("withold", "witthold", "withholde"),
}


def spelling_correct(rng: random.Random) -> dict:
    word = rng.choice(sorted(MISSPELLINGS))
    return _q(
        rng, "spelling",
        stem="Which word is spelled correctly?",
        answer=word,
        distractors=list(MISSPELLINGS[word]),
        explanation=f"The correct spelling is \"{word}\".",
        difficulty=1,
    )


def spelling_misspelled(rng: random.Random) -> dict:
    correct = rng.sample(sorted(MISSPELLINGS), 4)
    target = correct.pop()
    wrong = rng.choice(MISSPELLINGS[target])
    return _q(
        rng, "spelling",
        stem="Which word is MISSPELLED?",
        answer=wrong,
        distractors=correct,
        explanation=f"\"{wrong}\" should be spelled \"{target}\". The other words are spelled correctly.",
        difficulty=2,
    )


GENERATORS: dict[str, Callable[[random.Random], dict]] = {
    "filing_order": filing_order,
    "spelling": lambda rng: (spelling_correct if rng.random() < 0.5 else spelling_misspelled)(rng),
}
