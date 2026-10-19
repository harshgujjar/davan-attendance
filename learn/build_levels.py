# Placement content: levels 3-10 + mock tests -> learn/bank.json (rerun: python3 learn/build_levels.py).
# Levels 1-2 stay as they are; 3-9 are rebuilt here (hand-written data + number questions computed by code, so answers are always
# right); level 10 = PRO (12 mixed questions picked by the app from levels 1-9). Every question's options are shuffled with a fixed
# seed (the widget shows them in this order), and the answer index follows.
import json, random, math, hashlib, os
F = os.path.join(os.path.dirname(__file__), 'bank.json')
B = json.load(open(F))

def Q(q, o, e, tag=None):   # o[0] = right answer (shuffled later)
    d = {"q": q, "o": [str(x) for x in o], "a": 0, "e": e}
    if tag: d["tag"] = tag
    return d
def C(t, b, box, kn): return {"t": t, "b": b, "box": box, "kn": kn}
def L(n, name, tag, cards, qs): return {"n": n, "name": name, "tag": tag, "cards": cards, "qs": qs}
def H(rows):   # hand-written: [q, [right, w1, w2, w3], explanation]
    return [Q(r[0], r[1], r[2] if len(r) > 2 else "", r[3] if len(r) > 3 else None) for r in rows]
def opt(ans, *wr):
    o = [ans]
    for w in wr:
        if w not in o and w != '' and len(o) < 4: o.append(w)
    k = 1
    while len(o) < 4:
        if isinstance(ans, (int, float)) and ans + k not in o: o.append(ans + k)
        k += 1
    return o
fmt = lambda x: f"{x:,}" if isinstance(x, int) else str(x)
R = lambda s: random.Random(s)

# ── QUANT 3-9 (computed) ──
def ratio(r):
    out = []
    for a, b in [(2, 3), (3, 5), (4, 5)]:
        m = r.choice([100, 200, 300]); T = (a + b) * m; ans = b * m
        out.append(Q(f"Divide ₹{fmt(T)} between Ravi and Asha in the ratio {a} : {b}. Asha's share?", [f"₹{fmt(x)}" for x in opt(ans, a * m, T // 2, ans + m)], f"One part = {fmt(T)} ÷ {a + b} = {m}; Asha = {b} × {m} = {fmt(ans)}."))
    for p, q, s in [(2, 3, 4), (3, 4, 5)]:
        g = math.gcd(p, s); out.append(Q(f"A : B = {p} : {q} and B : C = {q} : {s}. A : C = ?", [f"{p // g} : {s // g}", f"{q} : {s}", f"{p} : {q}", f"{s} : {p}"], f"B is {q} in both, so A : C = {p} : {s}."))
    a, b, m = 3, 4, r.choice([8, 9, 12]); out.append(Q(f"Boys : girls = {a} : {b}. There are {a * m} boys. How many girls?", opt(b * m, a * m, b * m + a, (a + b) * m), f"One part = {a * m} ÷ {a} = {m}; girls = {b} × {m} = {b * m}."))
    return out
def avg(r):
    out = []
    for _ in range(2):
        xs = [r.randint(10, 40) for _ in range(4)]; t = sum(xs); x5 = 5 * math.ceil(t / 5) + 5 - t + 5 * r.randint(0, 3); xs.append(x5); s = sum(xs)
        out.append(Q(f"Average of {', '.join(map(str, xs))}?", opt(s // 5, s // 5 + 2, s // 4, s // 5 - 3), f"Sum {s} ÷ 5 = {s // 5}."))
    A = r.choice([20, 25, 30]); X = A + 5 * r.choice([1, 2, 3]); out.append(Q(f"The average of 4 numbers is {A}. A fifth number {X} is added. New average?", opt((4 * A + X) // 5, A, X, (A + X) // 2), f"(4 × {A} + {X}) ÷ 5 = {(4 * A + X) // 5}."))
    out.append(Q("The average age of 10 friends is 20. One friend aged 29 leaves. New average?", opt(19, 20, 18, 21), "Total 200 − 29 = 171; 171 ÷ 9 = 19."))
    for x, y in [(40, 60), (30, 60)]:
        out.append(Q(f"You go to college at {x} km/h and return the same way at {y} km/h. Average speed?", opt(2 * x * y // (x + y), (x + y) // 2, y - x, x), f"Same distance both ways: 2xy ÷ (x + y) = {2 * x * y // (x + y)} km/h (not the simple average).", "Workplace situation"))
    return out
def interest(r):
    out = []
    P, Rr, T = r.choice([5000, 8000, 12000]), r.choice([5, 8, 10]), r.choice([2, 3]); si = P * Rr * T // 100
    out.append(Q(f"Simple interest on ₹{fmt(P)} at {Rr}% a year for {T} years?", [f"₹{fmt(x)}" for x in opt(si, si // T, P * Rr // 100 * (T + 1), si * 2)], f"{fmt(P)} × {Rr} × {T} ÷ 100 = {fmt(si)}."))
    out.append(Q(f"You put ₹{fmt(P)} in a bank at {Rr}% simple interest. Amount after {T} years?", [f"₹{fmt(x)}" for x in opt(P + si, si, P + si // T, P + 2 * si)], f"Interest {fmt(si)} + principal {fmt(P)} = {fmt(P + si)}.", "Workplace situation"))
    for P, rr in [(1000, 10), (5000, 10)]:
        ci = P * (100 + rr) ** 2 // 10000 - P
        out.append(Q(f"Compound interest on ₹{fmt(P)} at {rr}% a year for 2 years?", [f"₹{fmt(x)}" for x in opt(ci, P * rr * 2 // 100, ci + P // 100, P * rr // 100)], f"{fmt(P)} × 1.{rr // 10 if rr == 10 else rr} × 1.{rr // 10 if rr == 10 else rr} − {fmt(P)} = {fmt(ci)} (CI is more than SI {fmt(P * rr * 2 // 100)})."))
    out.append(Q("At what simple interest rate does money double in 10 years?", ["10%", "20%", "5%", "12%"], "Interest = principal in 10 years → 100% ÷ 10 = 10% a year."))
    out.append(Q("CI − SI on ₹10,000 at 10% for 2 years?", ["₹100", "₹1,000", "₹200", "₹10"], "P × (r/100)² = 10,000 × 0.01 = 100."))
    return out
def work(r):
    out = []
    for a, b in r.sample([(10, 15), (12, 24), (20, 30), (6, 12), (12, 36)], 3):
        t = a * b // (a + b); out.append(Q(f"A finishes a job in {a} days, B in {b} days. Together?", [f"{x} days" for x in opt(t, (a + b) // 2, b - a, t + 3, t + 5)], f"1/{a} + 1/{b} = 1/{t}, so {t} days."))
    out.append(Q("12 people finish a job in 10 days. How many days for 8 people?", ["15 days", "8 days", "12 days", "20 days"], "People × days stays the same: 120 ÷ 8 = 15."))
    out.append(Q("A pipe fills a tank in 10 hours, another empties it in 15 hours. Both open: tank full in?", ["30 hours", "25 hours", "6 hours", "12 hours"], "1/10 − 1/15 = 1/30 → 30 hours."))
    out.append(Q("A works twice as fast as B. Together they finish in 6 days. A alone?", ["9 days", "12 days", "18 days", "3 days"], "B's rate x, A's 2x: 3x = 1/6 → x = 1/18; A = 2/18 = 1/9 → 9 days."))
    return out
def speed(r):
    out = []
    for k in r.sample([36, 54, 72, 90], 2): out.append(Q(f"{k} km/h = ? m/s", opt(k * 5 // 18, k // 3, k * 18 // 5, k // 2), f"× 5/18: {k} × 5 ÷ 18 = {k * 5 // 18} m/s."))
    L_, s = r.choice([(150, 54), (200, 72), (250, 90)]); t = L_ * 18 // (s * 5)
    out.append(Q(f"A {L_} m train at {s} km/h passes a pole in?", [f"{t} s", f"{t * 2} s", f"{L_ // s} s", f"{t + 5} s"], f"{s} km/h = {s * 5 // 18} m/s; {L_} ÷ {s * 5 // 18} = {t} s."))
    out.append(Q("A bus at 60 km/h covers how much in 2 h 30 min?", ["150 km", "120 km", "180 km", "130 km"], "60 × 2.5 = 150 km."))
    out.append(Q("Two buses 300 km apart drive towards each other at 70 and 80 km/h. They meet after?", ["2 hours", "3 hours", "4 hours", "1.5 hours"], "Speeds add: 150 km/h; 300 ÷ 150 = 2 h."))
    out.append(Q("You walk 6 km in 1 h 30 min. Your speed?", ["4 km/h", "6 km/h", "3 km/h", "9 km/h"], "6 ÷ 1.5 = 4 km/h."))
    return out
def numsys(r):
    out = []
    a, b = r.choice([(12, 18), (24, 36), (15, 25)]); out.append(Q(f"HCF of {a} and {b}?", opt(math.gcd(a, b), a * b // math.gcd(a, b), math.gcd(a, b) * 2, 3), "Largest number that divides both."))
    a, b = r.choice([(4, 6), (8, 12), (6, 10)]); l = a * b // math.gcd(a, b); out.append(Q(f"LCM of {a} and {b}?", opt(l, a * b, math.gcd(a, b), l * 2), "Smallest number both divide into."))
    n = r.choice([22, 23, 25, 26]); u = [7, 9, 3, 1][(n - 1) % 4]; out.append(Q(f"Unit digit of 7^{n}?", opt(u, (u + 2) % 10, 7, 1 if u != 1 else 3), "7, 9, 3, 1 repeat every 4 powers."))
    out.append(Q("Smallest number divisible by 6, 8 and 12?", opt(24, 48, 12, 96), "LCM(6, 8, 12) = 24."))
    out.append(Q("Which number is divisible by 9?", ["4,383", "4,382", "4,384", "4,385"], "Digit sum 4+3+8+3 = 18, divisible by 9."))
    out.append(Q("Remainder when 100 is divided by 7?", opt(2, 3, 1, 4), "7 × 14 = 98; 100 − 98 = 2."))
    return out
def di(r):
    v = [r.choice(range(30, 81, 5)) for _ in range(4)]; nm = "ABCD"; t = sum(v)
    tab = "Sales (₹ lakh): " + " · ".join(f"Shop {nm[i]} {v[i]}" for i in range(4)) + ". "
    hi = max(range(4), key=lambda i: v[i]); lo = min(range(4), key=lambda i: v[i])
    out = [Q(tab + "Total sales?", opt(t, t + 10, t - 5, max(v) * 4), "Add all four."),
           Q(tab + "Which shop sold the most?", [f"Shop {nm[hi]}"] + [f"Shop {nm[i]}" for i in range(4) if i != hi], "Look for the largest number."),
           Q(tab + f"Shop {nm[hi]} sold how much more than Shop {nm[lo]}?", opt(v[hi] - v[lo], v[hi] + v[lo], v[hi], v[lo]), f"{v[hi]} − {v[lo]} = {v[hi] - v[lo]}.")]
    g = math.gcd(v[0], v[1]); out.append(Q(tab + "Ratio of A to B?", [f"{v[0] // g} : {v[1] // g}", f"{v[1] // g} : {v[0] // g}", f"{v[0]} : {t}", "1 : 1" if v[0] != v[1] else "2 : 1"], "Divide both by their HCF."))
    out.append(Q(tab + "Average sales per shop?", opt(round(t / 4, 2) if t % 4 else t // 4, t // 3, max(v), min(v)), f"{t} ÷ 4."))
    a, b = r.choice([(40, 50), (50, 60), (60, 75)]); out.append(Q(f"Sales rose from ₹{a} lakh to ₹{b} lakh. % increase?", [f"{(b - a) * 100 // a}%", f"{b - a}%", f"{(b - a) * 100 // b}%", f"{(b - a) * 100 // a + 5}%"], f"({b} − {a}) ÷ {a} × 100.", "Workplace situation"))
    return out
QUANT = [(3, "Ratio & proportion", "Infosys pattern", ratio, [C("Ratio = parts", "Add the parts, find one part, multiply.", "₹500 in 2 : 3 → one part 100 → 200 and 300", "ಭಾಗಗಳನ್ನು ಕೂಡಿ, ಒಂದು ಭಾಗ ಕಂಡುಹಿಡಿಯಿರಿ"), C("Link two ratios", "Make the common term the same, then join.", "A:B = 2:3, B:C = 3:4 → A:C = 2:4", "ಸಾಮಾನ್ಯ ಪದ ಒಂದೇ ಮಾಡಿ")]),
         (4, "Averages", "AMCAT pattern", avg, [C("Average = total ÷ count", "Work with totals, not averages.", "Average 20 of 10 → total 200", "ಮೊತ್ತದಲ್ಲಿ ಲೆಕ್ಕ ಮಾಡಿ"), C("Average speed trap", "Same distance both ways is NOT (x + y) ÷ 2.", "2xy ÷ (x + y)", "ಸರಾಸರಿ ವೇಗ ಸೂತ್ರ")]),
         (5, "Simple & compound interest", "TCS NQT pattern", interest, [C("Simple interest", "Interest only on the principal.", "SI = P × R × T ÷ 100", "ಸರಳ ಬಡ್ಡಿ"), C("Compound interest", "Interest on interest too.", "A = P (1 + R/100)ⁿ", "ಚಕ್ರಬಡ್ಡಿ")]),
         (6, "Time & work", "Accenture pattern", work, [C("Work per day", "A in 10 days → 1/10 of the job a day. Add rates when working together.", "1/a + 1/b = 1/T", "ದಿನಕ್ಕೆ ಎಷ್ಟು ಕೆಲಸ"), C("People × days", "Same job: people × days stays the same.", "12 × 10 = 8 × 15", "ಜನ × ದಿನ ಸ್ಥಿರ")]),
         (7, "Speed, distance & time", "TCS NQT pattern", speed, [C("D = S × T", "Distance = speed × time. Keep units the same.", "km/h × 5/18 = m/s", "ದೂರ = ವೇಗ × ಸಮಯ"), C("Trains", "Passing a pole: distance = train length.", "Time = length ÷ speed", "ರೈಲು ಉದ್ದ = ದೂರ")]),
         (8, "Number system", "Infosys pattern", numsys, [C("HCF and LCM", "HCF = biggest common divisor. LCM = smallest common multiple.", "HCF × LCM = a × b", "ಮ.ಸಾ.ಅ. ಮತ್ತು ಲ.ಸಾ.ಅ."), C("Unit digits", "Powers repeat every 4: 7, 9, 3, 1.", "7²³ → 23 = 4×5+3 → 3", "ಘಾತಗಳ ಕೊನೆಯ ಅಂಕೆ")]),
         (9, "Data interpretation", "TCS NQT pattern", di, [C("Read the table first", "Note units (₹ lakh, %) before you calculate.", "Units first → then maths", "ಘಟಕಗಳನ್ನು ಗಮನಿಸಿ"), C("% change", "Divide the change by the OLD value.", "(New − Old) ÷ Old × 100", "ಹಳೆಯ ಮೌಲ್ಯದಿಂದ ಭಾಗಿಸಿ")])]

# ── REASONING 3-9 ──
def clock(r):
    out = []
    for h, m in r.sample([(3, 0), (2, 30), (4, 20), (7, 0), (9, 15), (6, 0)], 3):
        a = abs(30 * h - 5.5 * m); a = min(a, 360 - a); a = int(a) if a == int(a) else a
        cand = [a, int(30 * h) % 360, int(abs(30 * h - 6 * m)), abs(180 - a), a + 30, 90, 45]; o = []
        for x in cand:
            if x not in o and len(o) < 4: o.append(x)
        out.append(Q(f"Angle between the clock hands at {h}:{m:02d}?", [f"{x}°" for x in o], "Angle = |30 × hours − 5.5 × minutes|."))
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    for k in r.sample([10, 15, 20, 30, 45], 2):
        d0 = r.randint(0, 6); ans = days[(d0 + k) % 7]
        out.append(Q(f"Today is {days[d0]}. What day is it after {k} days?", [ans] + [days[(d0 + k + j) % 7] for j in (1, 2, 6)], f"{k} = 7 × {k // 7} + {k % 7}: move {k % 7} day(s) on."))
    out.append(Q("How many times do the clock hands overlap in 12 hours?", ["11", "12", "24", "22"], "Once every 12/11 hours → 11 times."))
    return out
def rank(r):
    out = []
    for _ in range(2):
        n = r.randint(25, 45); k = r.randint(5, 15); out.append(Q(f"In a class of {n}, Ravi is {k}th from the top. His rank from the bottom?", opt(n - k + 1, n - k, n - k + 2, k), "From bottom = total − top rank + 1."))
    a, b = r.randint(6, 12), r.randint(5, 10); out.append(Q(f"Asha is {a}th from the left and {b}th from the right in a row. How many in the row?", opt(a + b - 1, a + b, a + b + 1, a + b - 2), "Left + right − 1 (Asha counted twice)."))
    out.append(Q("A is taller than B. C is taller than A. D is shorter than B. Who is the tallest?", ["C", "A", "B", "D"], "C > A > B > D."))
    out.append(Q("P scored more than Q but less than R. S scored less than Q. Who scored the least?", ["S", "Q", "P", "R"], "R > P > Q > S."))
    out.append(Q("In a queue, Ravi is 10th from the front and there are 6 people behind him. How many in the queue?", opt(16, 15, 17, 10), "10 + 6 = 16."))
    return out
REASON = [(3, "Blood relations", "TCS NQT pattern", [C("Draw a family tree", "Up = parent, side = sibling, down = child.", "A ─ B (siblings) · C ↓ D (parent → child)", "ಕುಟುಂಬ ಮರ ಚಿತ್ರಿಸಿ"), C("Key words", "Father's sister = aunt. Mother's brother = maternal uncle.", "Uncle's child = cousin", "ಸಂಬಂಧದ ಪದಗಳು")],
           H([["A is B's father. C is A's father. C is B's?", ["Grandfather", "Father", "Uncle", "Brother"], "Father's father = grandfather."],
              ["Ravi (a boy) is asked: who is your mother's only son?", ["Ravi himself", "Ravi's uncle", "Ravi's father", "Ravi's cousin"], "The only son of Ravi's mother is Ravi."],
              ["P is Q's sister. Q is R's son. P is R's?", ["Daughter", "Sister", "Mother", "Niece"], "Q's sister is also R's child, and a girl."],
              ["My father's sister is my?", ["Aunt", "Niece", "Cousin", "Sister-in-law"], "Father's sister = aunt."],
              ["Pointing to a man, Asha says, 'His mother is my mother's only daughter.' The man is Asha's?", ["Son", "Brother", "Father", "Nephew"], "Her mother's only daughter is Asha herself → the man is her son."],
              ["A is B's brother. B is C's mother. A is C's?", ["Uncle", "Father", "Brother", "Grandfather"], "Mother's brother = uncle."]])),
          (4, "Direction sense", "Wipro pattern", [C("Draw it", "North up, East right. Draw every move.", "N ↑ · E → · S ↓ · W ←", "ದಿಕ್ಕುಗಳನ್ನು ಚಿತ್ರಿಸಿ"), C("Turns", "Right turn = clockwise 90°.", "Facing North + right → East", "ಬಲ ತಿರುವು = ಘಡಿಯ ದಿಕ್ಕು")],
           H([["Facing North, you turn right. Now facing?", ["East", "West", "South", "North"]], ["Facing East, you turn left twice. Now facing?", ["West", "North", "South", "East"], "Left → North, left again → West."],
              ["Walk 3 km North, then 4 km East. Straight distance from start?", ["5 km", "7 km", "1 km", "12 km"], "3-4-5 triangle."], ["Facing South, you turn right. Now facing?", ["West", "East", "North", "South"]],
              ["Walk 5 km East, then 5 km West. Distance from start?", ["0 km", "10 km", "5 km", "25 km"], "You are back at the start."], ["Your shadow falls behind you in the morning. You are facing?", ["East", "West", "North", "South"], "Morning sun is in the East, in front of you."]])),
          (5, "Syllogisms", "Infosys pattern", [C("Draw circles", "Each statement = circles (Venn).", "All A are B → A inside B", "ವೃತ್ತ ಚಿತ್ರಿಸಿ"), C("Only what MUST be true", "'Some' = overlap. A conclusion follows only if it is true in every drawing.", "Possible ≠ follows", "ಖಚಿತವಾದದ್ದು ಮಾತ್ರ")],
           H([["All cats are animals. All animals breathe. → All cats breathe.", ["Follows", "Does not follow", "Only sometimes", "Cannot be true"]],
              ["All pens are blue. Some blue things are cars. → Some pens are cars.", ["Does not follow", "Follows", "Always true", "Both are true"], "The cars may be outside the pen circle."],
              ["No apple is a stone. All stones are hard. → No apple is hard.", ["Does not follow", "Follows", "Definitely true", "Both are true"], "Apples could still be hard."],
              ["All students are learners. Ravi is a student. → Ravi is a learner.", ["Follows", "Does not follow", "Cannot say", "False"]],
              ["Some books are pens. All pens are red. → Some books are red.", ["Follows", "Does not follow", "Cannot say", "False"], "The books that are pens are red."],
              ["No dog is a cat. Some cats are pets. → Some pets are not dogs.", ["Follows", "Does not follow", "Cannot say", "False"], "Those pets are cats, so not dogs."]])),
          (6, "Seating arrangement", "AMCAT pattern", [C("Draw the seats", "Draw a row and fill the sure facts first.", "_ _ _ _ _ (left → right)", "ಆಸನ ಚಿತ್ರಿಸಿ"), C("Between / next to", "'M is between N and O' → N M O or O M N.", "Try both, keep the one that fits", "ಎರಡೂ ಪ್ರಯತ್ನಿಸಿ")],
           H([["A, B, C, D, E sit in a row. C is in the middle, A at the left end, E at the right end, B next to E. Who is second from the left?", ["D", "B", "E", "C"], "A D C B E."],
              ["P is left of Q, Q left of R, R left of S, S left of T. Who is in the middle?", ["R", "Q", "S", "P"], "P Q R S T."],
              ["4 in a row: Asha right of Ben, Ben right of Chitra, Dev at the right end. Who is at the left end?", ["Chitra", "Ben", "Asha", "Dev"], "Chitra Ben Asha Dev."],
              ["X, Y, Z sit in a row. Y is not at an end. X is left of Y. Who is at the right end?", ["Z", "X", "Y", "Cannot say"], "X Y Z."],
              ["M is between N and O. P is at the right end, next to O. Order from the left?", ["N M O P", "O M N P", "P O M N", "M N O P"]],
              ["Ravi is 7th from the left and 3rd from the right in a row. How many people?", ["9", "10", "8", "11"], "7 + 3 − 1."]])),
          (7, "Analogy & odd one out", "Accenture pattern", [C("Say the link", "Put the pair in a sentence: 'A doctor works in a hospital'.", "Doctor : Hospital :: Teacher : School", "ಸಂಬಂಧ ಹೇಳಿ"), C("Odd one out", "Find the rule three share; the fourth breaks it.", "2, 3, 5, 9 → 9 is not prime", "ಬೇರೆಯಾದದ್ದು")],
           H([["Doctor : Hospital :: Teacher : ?", ["School", "Book", "Student", "Pen"]], ["Odd one out", ["Carrot", "Apple", "Mango", "Banana"], "Carrot is a vegetable."],
              ["Pen : Write :: Knife : ?", ["Cut", "Cook", "Eat", "Sharp"]], ["Odd one out: 2, 3, 5, 9", ["9", "2", "3", "5"], "9 is not prime."],
              ["Bird : Fly :: Fish : ?", ["Swim", "Water", "Fins", "Eat"]], ["Odd one out", ["Python", "Monitor", "Keyboard", "Mouse"], "Python is software; the rest are hardware."]])),
          (8, "Clocks & calendars", "AMCAT pattern", [C("Clock angle", "Hour hand 30° per hour + 0.5° per minute; minute hand 6° per minute.", "Angle = |30H − 5.5M|", "ಘಡಿಯಾರ ಕೋನ"), C("Odd days", "Every 7 days the weekday repeats; only the remainder moves it.", "15 days = 2 weeks + 1 day", "7 ರಿಂದ ಭಾಗಿಸಿ ಶೇಷ")], None),
          (9, "Ranking & order", "TCS NQT pattern", [C("Rank from both ends", "Total = left + right − 1.", "Bottom rank = total − top + 1", "ಎರಡೂ ಕಡೆಯ ಸ್ಥಾನ"), C("Order puzzles", "Write a > b chain as you read.", "C > A > B > D", "ಕ್ರಮ ಬರೆಯಿರಿ")], None)]

VERBAL = [(3, "Tenses", "Wipro pattern", [C("Habit or now?", "Habits → present simple. Right now → present continuous.", "I go daily · I am going now", "ಅಭ್ಯಾಸ / ಈಗ"), C("Finished time", "Yesterday / last week → past simple. Since / for → present perfect.", "I sent it yesterday · I have lived here since 2020", "ನಿನ್ನೆ → past")],
           H([["She ___ in Bengaluru since 2020.", ["has lived", "lives", "lived", "is living"], "'since' → present perfect."], ["I ___ the report yesterday.", ["sent", "have sent", "send", "am sending"], "'yesterday' → past simple."],
              ["Look! It ___.", ["is raining", "rains", "rained", "has rain"], "Happening now."], ["He ___ to the gym every morning.", ["goes", "is going", "gone", "go"], "Habit."],
              ["By next year, I ___ my degree.", ["will have finished", "finish", "finished", "am finishing"], "Done before a future time."], ["When I reached, the bus ___.", ["had left", "has left", "leaves", "leaving"], "The earlier past action → had + V3."]])),
          (4, "Prepositions", "Accenture pattern", [C("at / on / in", "at a time · on a day · in a month or year.", "at 10 am · on Monday · in 2026", "ಸಮಯ at, ದಿನ on, ವರ್ಷ in"), C("Fixed pairs", "interested in · good at · depend on · reply to", "Learn them as pairs", "ಜೋಡಿ ಪದಗಳು")],
           H([["The interview is ___ Monday.", ["on", "in", "at", "by"]], ["Come ___ 10 am.", ["at", "on", "in", "of"]], ["I was born ___ 2005.", ["in", "on", "at", "by"]],
              ["She is interested ___ data science.", ["in", "on", "at", "for"]], ["Please reply ___ this email.", ["to", "at", "for", "on"]], ["It depends ___ the result.", ["on", "of", "in", "at"]]])),
          (5, "Reading comprehension", "Infosys pattern", [C("Question first", "Read the question, then the passage - you know what to look for.", "Question → passage → answer", "ಮೊದಲು ಪ್ರಶ್ನೆ"), C("Stay in the passage", "Choose what the passage says, not what you think.", "Facts in the text win", "ಪಠ್ಯದಲ್ಲಿರುವುದೇ ಉತ್ತರ")],
           H([["'Ravi joined a startup in Bengaluru. In six months he learnt Python and led a small team.' What did Ravi learn?", ["Python", "Java", "Team sports", "Accounting"]],
              ["'Fresh graduates get three months of training before they join a project.' How long is the training?", ["3 months", "6 months", "1 year", "3 weeks"]],
              ["'Candidates who skip hard questions and return later usually score higher.' What helps you score higher?", ["Skipping hard questions and returning later", "Answering strictly in order", "Leaving early", "Guessing everything"]],
              ["'Meera saved ₹2,000 every month for a year to buy a laptop.' How much did she save?", ["₹24,000", "₹12,000", "₹2,000", "₹20,000"], "2,000 × 12."],
              ["'Good listeners do not interrupt. They wait, then ask questions.' The main idea is", ["How to be a good listener", "How to speak fast", "How to ask for leave", "How to interrupt politely"]],
              ["'The office opens at 9:30 am, but the team meets at 9 am on Mondays.' When does the team meet on Monday?", ["9 am", "9:30 am", "10 am", "8:30 am"]]])),
          (6, "Para-jumbles", "TCS NQT pattern", [C("Find the opener", "The first sentence introduces the topic; it rarely starts with He / This / However / So.", "Topic → details → ending", "ಮೊದಲ ವಾಕ್ಯ ಪರಿಚಯ"), C("Link words", "then, so, however, this → they point back to an earlier sentence.", "'This' needs something before it", "ಸಂಪರ್ಕ ಪದಗಳು")],
           H([["(P) Then he applied online. (Q) Ravi saw a job advert. (R) A week later he got a call.", ["QPR", "PQR", "RQP", "QRP"]], ["(P) She practised every day. (Q) Asha wanted to speak English well. (R) Now she speaks confidently.", ["QPR", "PQR", "QRP", "RPQ"]],
              ["(P) So the shop raised its prices. (Q) The cost of milk went up. (R) Customers started buying less.", ["QPR", "PQR", "RQP", "QRP"]], ["(P) This made the work faster. (Q) The office bought new computers. (R) Everyone finished early that month.", ["QPR", "PRQ", "RQP", "QRP"]],
              ["(P) He studied the company's products. (Q) Before the interview, Arun read about the company. (R) He answered every question with confidence.", ["QPR", "PQR", "RPQ", "QRP"]], ["(P) However, it started raining. (Q) We planned a picnic on Sunday. (R) So we stayed home and watched a movie.", ["QPR", "PQR", "QRP", "RQP"]]])),
          (7, "Idioms & phrases", "AMCAT pattern", [C("Not word for word", "'Break the ice' has nothing to do with ice.", "Break the ice = start a friendly talk", "ಪದಶಃ ಅರ್ಥವಲ್ಲ"), C("Learn in sentences", "Remember the whole sentence.", "I hit the books before exams", "ವಾಕ್ಯದಲ್ಲಿ ನೆನಪಿಡಿ")],
           H([["'Break the ice' means", ["start a friendly conversation", "break something", "feel cold", "stop talking"]], ["'Piece of cake' means", ["very easy", "a dessert", "a small part", "very costly"]],
              ["'Hit the books' means", ["study hard", "throw books", "buy books", "sell books"]], ["'Once in a blue moon' means", ["very rarely", "every night", "every month", "never"]],
              ["'Under the weather' means", ["feeling ill", "outside", "very happy", "in the rain"]], ["'Call it a day' means", ["stop working for today", "phone someone", "start the day", "name a day"]]])),
          (8, "One-word substitution", "Wipro pattern", [C("Word parts", "bi = two · il / in = not · auto = self", "Bilingual · Illegible · Autobiography", "ಪದದ ಭಾಗಗಳು"), C("Office words", "Agenda before a meeting, minutes after.", "Agenda → meeting → minutes", "ಸಭೆ ಪದಗಳು")],
           H([["A person who speaks two languages", ["Bilingual", "Biography", "Bilateral", "Bicycle"]], ["One who works without pay", ["Volunteer", "Employee", "Manager", "Trainee"]],
              ["A list of things to discuss at a meeting", ["Agenda", "Minutes", "Memo", "Notice"]], ["Writing that cannot be read", ["Illegible", "Eligible", "Invisible", "Illegal"]],
              ["A person who starts a business", ["Entrepreneur", "Employee", "Customer", "Auditor"]], ["A written record of a meeting", ["Minutes", "Agenda", "Notice", "Circular"]]])),
          (9, "Sentence improvement", "Wipro pattern", [C("Common errors", "senior TO · prefer A TO B · discuss (no 'about')", "He is senior to me", "ಸಾಮಾನ್ಯ ತಪ್ಪುಗಳು"), C("did + base verb", "After did / does / do use the base verb.", "did not come (not came)", "did ನಂತರ ಮೂಲ ರೂಪ")],
           H([["Improve: 'He is senior than me.'", ["senior to me", "more senior than me", "seniorer than me", "No improvement"]], ["Improve: 'I prefer tea than coffee.'", ["prefer tea to coffee", "prefer tea over than coffee", "prefers tea than coffee", "No improvement"]],
              ["Improve: 'She did not came yesterday.'", ["did not come", "does not came", "did not comes", "No improvement"]], ["Improve: 'Each of the boys have a bat.'", ["has a bat", "are having a bat", "have bats", "No improvement"]],
              ["Improve: 'We discussed about the plan.'", ["discussed the plan", "discussed on the plan", "discuss about the plan", "No improvement"]], ["Improve: 'I have completed the work yesterday.'", ["completed the work yesterday", "have complete the work yesterday", "had completed yesterday the work", "No improvement"]]]))]

ENGLISH = [(3, "Group discussion", "Workplace situation", [C("Agree, then add", "I agree with Ravi, and I'd add that…", "Agree → your point → example", "ಒಪ್ಪಿ ಸೇರಿಸಿ"), C("Disagree politely", "I see your point, but… · I'd look at it differently.", "Never 'You are wrong'", "ವಿನಯದ ಅಸಮ್ಮತಿ")],
            H([["Polite way to disagree", ["I see your point, but I think…", "You are wrong.", "That's nonsense.", "Stop talking."]], ["Best way to start a GD", ["I'd like to begin by saying…", "Listen to me first!", "Nobody knows this topic.", "I don't know."]],
               ["Adding to someone's idea", ["Building on Asha's point, …", "Asha is right, the end.", "That was my idea.", "Whatever."]], ["Ending a GD", ["To sum up, we agreed that…", "OK, bye.", "I won.", "That's all, finish."]],
               ["Someone interrupts you", ["May I finish my point, please?", "Shut up!", "Let me speak!!", "Shout louder"]], ["A member has not spoken", ["Priya, what do you think?", "Priya never talks.", "Skip Priya.", "Someone else talk."]]])),
           (4, "Meetings & phone calls", "Workplace situation", [C("Clear and polite", "Short sentences with please and thank you.", "Could you please… · Thank you for…", "ಸ್ಪಷ್ಟ, ವಿನಯ"), C("Confirm details", "Repeat numbers, dates and times back.", "So that's Friday, 5 pm, right?", "ಮತ್ತೆ ದೃಢಪಡಿಸಿ")],
            H([["You join a call late", ["Sorry I'm late. Could you give me a quick update?", "Why didn't you wait?", "What happened?", "Start again."]], ["Ending a call", ["Thank you for your time. Have a good day.", "Bye, cutting.", "Done.", "OK."]],
               ["Asking a client to wait", ["Could you please hold for a moment?", "Wait.", "Hold on, man.", "Don't go."]], ["You didn't hear a number", ["Sorry, could you repeat the number slowly, please?", "What?", "Again!", "Number?"]],
               ["Agreeing to a deadline", ["Sure, I'll send it by Friday 5 pm.", "Maybe.", "I'll try sometime.", "Not possible."]], ["Taking a message", ["May I take a message for her?", "She's not here.", "Call later.", "Who are you?"]]])),
           (5, "Common mistakes", "HR interview", [C("Small words matter", "explain TO me · married TO · discuss (no 'about')", "Please explain this to me", "ಸಣ್ಣ ಪದಗಳು ಮುಖ್ಯ"), C("Question, not doubt", "In global English you ask a question; 'doubt' means you don't believe it.", "I have a question about step 2", "doubt ಬದಲು question")],
            H([["Correct sentence", ["Please explain this to me.", "Please explain me this.", "Explain me this please.", "Me explain this."]], ["Correct sentence", ["I will call you back.", "I will revert back to you.", "I will back call you.", "I will call back you."]],
               ["Correct sentence", ["I am in the third year.", "I am third year studying.", "Myself third year.", "I in third year."]], ["Correct sentence", ["She is married to Ravi.", "She is married with Ravi.", "She married with Ravi.", "She is marry to Ravi."]],
               ["Correct sentence", ["I have a question about this.", "I have a doubt on this.", "I am having doubt.", "Doubt is there."]], ["Correct sentence", ["Let's discuss the plan.", "Let's discuss about the plan.", "Let's discussion the plan.", "Lets discuss on plan."]]])),
           (6, "Interview answers", "HR interview", [C("STAR", "Situation, Task, Action, Result.", "S → T → A → R", "ಪರಿಸ್ಥಿತಿ, ಕೆಲಸ, ಕ್ರಮ, ಫಲಿತಾಂಶ"), C("Stay positive", "Never speak badly of a college, teacher or company.", "Talk about what you learnt", "ಸಕಾರಾತ್ಮಕವಾಗಿರಿ")],
            H([["'Why should we hire you?'", ["I learn fast, I've built projects in Java, and I want to grow with your team.", "I need a job.", "Because I am poor.", "I don't know."]],
               ["'Where do you see yourself in 5 years?'", ["In a senior role here, with strong skills.", "In another company.", "Abroad, not here.", "Sleeping."]],
               ["'Tell me about a challenge.'", ["Explain the problem, what you did and the result.", "Say you never had one.", "Blame others.", "Talk about movies."]],
               ["'Do you have any questions?'", ["What would a fresher learn here in the first 6 months?", "No.", "How many leaves?", "When is the salary?"]],
               ["'What salary do you expect?' (fresher)", ["I'm open to your standard package for freshers.", "The highest possible.", "Not below 10 lakh.", "Nothing."]],
               ["'Why do you want to join us?'", ["Name the company's work and how it fits your skills.", "It is near my home.", "My friend works here.", "Any job is fine."]]])),
           (7, "Resume writing", "Workplace situation", [C("Action + result", "Start with a verb, add a number.", "Organised a fest for 400 students", "ಕ್ರಿಯಾಪದ + ಫಲಿತಾಂಶ"), C("Keep it clean", "1 page, simple font, professional email.", "name.surname@gmail.com", "ಸರಳ, ಒಂದು ಪುಟ")],
            H([["Best resume line", ["Built a class attendance app used by 60 students (HTML, Firebase).", "Did a project.", "I am hardworking.", "Good at computers."]],
               ["Best career objective", ["BCA graduate seeking a junior developer role to use Java and SQL.", "To get a job.", "I want money.", "Any job."]],
               ["Leave this out of a resume", ["Father's name and full address", "Your skills", "Your projects", "Your email"]], ["Best skills line", ["Java · SQL · Excel · HTML/CSS", "Many skills", "All computer things", "MS Word only"]],
               ["Resume length for a fresher", ["1 page", "5 pages", "3 pages", "Half a line"]], ["Best email address on a resume", ["ananya.k2026@gmail.com", "cutebabygirl@gmail.com", "killer007@gmail.com", "abc@gmail.com"]]])),
           (8, "Customer handling", "Workplace situation", [C("Listen, sorry, solve", "Listen fully, apologise, give a clear next step.", "Listen → Apologise → Solve", "ಕೇಳಿ, ಕ್ಷಮೆ, ಪರಿಹಾರ"), C("Promise a time", "Give a clear time and keep it.", "I'll call you back by 4 pm", "ಸಮಯ ಹೇಳಿ, ಪಾಲಿಸಿ")],
            H([["An angry customer", ["I'm sorry for the trouble. Let me fix this for you.", "Not my problem.", "Calm down!", "Call someone else."]], ["You don't know the answer", ["Let me check and get back to you by 4 pm.", "I don't know.", "Google it.", "That's not possible."]],
               ["A delivery is late", ["I apologise for the delay; it will reach you tomorrow by noon.", "It's late, so what?", "Blame the courier.", "No idea."]], ["Greeting a visitor", ["Good morning! How may I help you?", "Yes?", "What do you want?", "Wait there."]],
               ["Saying no politely", ["I'm afraid we can't do that, but here's what we can do…", "No.", "Impossible, go.", "Never."]], ["Closing a conversation", ["Is there anything else I can help you with?", "Done, bye.", "Go now.", "That's all."]]])),
           (9, "Presentations", "Workplace situation", [C("Tell, show, tell", "Say what you'll cover, cover it, sum up.", "Opening → 3 points → summary", "ಹೇಳಿ, ತೋರಿಸಿ, ಮತ್ತೆ ಹೇಳಿ"), C("Practise aloud", "Practise twice aloud and time yourself.", "5 minutes ≈ 600 words", "ಜೋರಾಗಿ ಅಭ್ಯಾಸ")],
            H([["Best opening", ["Good morning. Today I'll show how our app saves time.", "Umm… so…", "Sorry, I'm not prepared.", "Let's begin I guess."]], ["Slides should have", ["few words, big points", "full paragraphs", "tiny text", "no titles"]],
               ["Where to look", ["at the audience", "at the floor", "only at the slides", "at the ceiling"]], ["You forget a point", ["Pause, check your notes, continue calmly.", "Say sorry many times.", "Stop and leave.", "Laugh."]],
               ["Best ending", ["Sum up the 3 key points and thank the audience.", "Just stop.", "Say 'that's all' and run.", "Read the last slide silently."]], ["Best speaking speed", ["steady and clear", "very fast", "very slow", "a whisper"]]]))]

def TECH(rows):
    out = []
    for n, name, tag, cards, qs in rows: out.append((n, name, tag, [C(*c) for c in cards], H(qs)))
    return out
BCA = TECH([
 (3, "Java & OOP", "Infosys pattern", [["4 pillars of OOP", "Encapsulation, Inheritance, Polymorphism, Abstraction.", "E · I · P · A", "OOP ನ 4 ಸ್ತಂಭಗಳು"], ["Java basics", "Everything is in a class; main is where it starts; objects are made with new.", "public static void main(String[] args)", "main ಇಂದ ಶುರು"]],
  [["Keyword to inherit a class", ["extends", "implements", "inherits", "super"]], ["Java source is compiled to", ["bytecode", "HTML", "Python", "only machine code"]], ["Method overloading is", ["compile-time polymorphism", "inheritance", "encapsulation", "run-time polymorphism"]],
   ["Which is NOT a primitive type in Java?", ["String", "int", "boolean", "char"]], ["Keeping data private inside a class is", ["Encapsulation", "Inheritance", "Polymorphism", "Compilation"]], ["System.out.println(10 + 20 + \"Hi\");", ["30Hi", "1020Hi", "Hi30", "Error"], "Left to right: 10 + 20 = 30, then joined with \"Hi\"."]]),
 (4, "Python", "TCS NQT pattern", [["Indentation", "Python groups code with spaces, not braces.", "if x > 5:\n    print('big')", "ಇಂಡೆಂಟೇಶನ್ ಮುಖ್ಯ"], ["Lists and slices", "Index from 0; a[1:3] gives items 1 and 2.", "a = [10, 20, 30, 40] → a[1:3] = [20, 30]", "ಕೊನೆಯ ಸ್ಥಾನ ಸೇರುವುದಿಲ್ಲ"]],
  [["print(len(\"Davan\"))", ["5", "4", "6", "Error"]], ["a = [10, 20, 30, 40]; print(a[1:3])", ["[20, 30]", "[10, 20]", "[20, 30, 40]", "[30, 40]"]], ["print(7 // 2)", ["3", "3.5", "4", "1"], "// is floor division."],
   ["print(2 ** 3)", ["8", "6", "9", "5"]], ["Which creates a dictionary?", ["{\"a\": 1}", "[\"a\", 1]", "(\"a\", 1)", "<a, 1>"]], ["print(\"ab\" * 3)", ["ababab", "ab3", "Error", "aabbb"]]]),
 (5, "Data structures", "Accenture pattern", [["Stack and queue", "Stack: last in, first out. Queue: first in, first out.", "Stack = plates · Queue = ticket line", "LIFO / FIFO"], ["Search", "Binary search needs a sorted list: O(log n).", "Linear O(n) · Binary O(log n)", "ಬೈನರಿ ಸರ್ಚ್"]],
  [["A stack follows", ["LIFO", "FIFO", "Random order", "Sorted order"]], ["A queue follows", ["FIFO", "LIFO", "Random order", "Priority only"]], ["Binary search needs", ["a sorted list", "a linked list", "a stack", "nothing special"]],
   ["Time taken by binary search", ["O(log n)", "O(n)", "O(n²)", "O(1)"]], ["Undo in a text editor uses a", ["Stack", "Queue", "Graph", "Hash table"]], ["A tree where each node has at most 2 children", ["Binary tree", "Graph", "Queue", "Linked list"]]]),
 (6, "Operating systems", "TCS NQT pattern", [["Process and thread", "A process is a running program; threads are smaller tasks inside it sharing its memory.", "1 process → many threads", "ಪ್ರೊಸೆಸ್ / ಥ್ರೆಡ್"], ["Deadlock", "Two processes wait for each other forever.", "A waits for B, B waits for A", "ಪರಸ್ಪರ ಕಾಯುವಿಕೆ"]],
  [["Which is an operating system?", ["Linux", "Python", "Chrome", "MySQL"]], ["Deadlock means", ["processes waiting for each other forever", "a fast CPU", "a virus", "a full disk"]], ["RAM is", ["volatile memory", "permanent storage", "a processor", "an OS"]],
   ["Scheduling that runs the shortest job first", ["SJF", "FCFS", "Round Robin", "LIFO"]], ["Virtual memory uses", ["disk space as extra memory", "a faster CPU", "only the cloud", "only cache"]], ["Threads of one process share", ["memory", "nothing", "separate disks", "separate OS"]]]),
 (7, "Computer networks", "Infosys pattern", [["IP and DNS", "An IP address finds a computer; DNS turns names into IP addresses.", "google.com → 142.250.x.x", "DNS = ಹೆಸರು → IP"], ["OSI model", "7 layers: Physical, Data link, Network, Transport, Session, Presentation, Application.", "Please Do Not Throw Sausage Pizza Away", "7 ಹಂತಗಳು"]],
  [["DNS converts", ["domain names to IP addresses", "IP to MAC", "text to voice", "files to PDF"]], ["Default port of HTTPS", ["443", "80", "21", "25"]], ["Number of OSI layers", ["7", "5", "4", "8"]],
   ["TCP is", ["connection-oriented and reliable", "connectionless", "a browser", "an IP address"]], ["Device that connects different networks", ["Router", "Monitor", "Keyboard", "Printer"]], ["Size of an IPv4 address", ["32 bits", "64 bits", "128 bits", "16 bits"]]]),
 (8, "Web technology", "Wipro pattern", [["HTML, CSS, JS", "HTML = structure, CSS = look, JavaScript = actions.", "Page = HTML + CSS + JS", "ರಚನೆ, ವಿನ್ಯಾಸ, ಕ್ರಿಯೆ"], ["Common tags", "<a> link · <img> image · <p> paragraph · <h1> main heading", "<a href=\"…\">Apply</a>", "ಟ್ಯಾಗ್‌ಗಳು"]],
  [["Tag for a link", ["<a>", "<link>", "<href>", "<url>"]], ["CSS is used for", ["styling the page", "storing data", "running a server", "compiling code"]], ["JavaScript mainly runs in", ["the browser", "the printer", "the BIOS", "Excel only"]],
   ["The largest heading", ["<h1>", "<h6>", "<head>", "<big>"]], ["Make text red in CSS", ["color: red;", "text: red;", "font-color = red", "red: text;"]], ["Form method that sends data in the request body", ["POST", "GET", "LINK", "HEAD"]]]),
 (9, "Software engineering", "Accenture pattern", [["SDLC", "Requirements → Design → Build → Test → Deploy → Maintain.", "R → D → B → T → D → M", "ಸಾಫ್ಟ್‌ವೇರ್ ಜೀವನಚಕ್ರ"], ["Agile and Git", "Agile = small steps every 1–2 weeks (sprints). Git saves versions of code.", "sprint · commit · push", "ಸಣ್ಣ ಹಂತಗಳು"]],
  [["First stage of the SDLC", ["Requirement gathering", "Testing", "Deployment", "Maintenance"]], ["Agile works in", ["short sprints", "one long phase", "no planning", "yearly releases"]], ["Git is used for", ["version control", "image editing", "email", "spreadsheets"]],
   ["Testing one function alone is", ["unit testing", "system testing", "beta testing", "load testing"]], ["A bug is", ["an error in the program", "a new feature", "a server", "a test plan"]], ["The waterfall model works", ["one phase after another", "in short repeated cycles", "with no design", "with testing only"]]])])
BBA = TECH([
 (3, "Marketing", "Workplace situation", [["STP", "Segment the market, Target a group, Position your product.", "Segment → Target → Position", "ವಿಭಾಗ, ಗುರಿ, ಸ್ಥಾನ"], ["Product life cycle", "Introduction → Growth → Maturity → Decline.", "I → G → M → D", "ಉತ್ಪನ್ನ ಜೀವನಚಕ್ರ"]],
  [["STP stands for", ["Segmentation, Targeting, Positioning", "Sales, Tax, Profit", "Stock, Trade, Price", "Supply, Target, Product"]], ["First stage of the product life cycle", ["Introduction", "Growth", "Maturity", "Decline"]],
   ["Selling more of the same product in the same market", ["Market penetration", "Diversification", "Product development", "Market development"]], ["USP means", ["Unique Selling Proposition", "United Sales Plan", "Usual Sales Price", "Unit Selling Price"]],
   ["A film star advertising a phone is part of", ["Promotion", "Price", "Place", "Product"]], ["Selling through an online store is part of", ["Place", "Price", "Promotion", "People"]]]),
 (4, "HR management", "HR / technical interview", [["Hiring steps", "Job analysis → advertise → shortlist → interview → offer → induction.", "Recruit → Select → Induct", "ನೇಮಕಾತಿ ಹಂತಗಳು"], ["Training vs development", "Training = skills for today's job. Development = growth for the future.", "An Excel course = training", "ತರಬೇತಿ / ಅಭಿವೃದ್ಧಿ"]],
  [["Induction means", ["introducing a new employee to the company", "firing", "promotion", "salary"]], ["Recruitment means", ["finding candidates to apply", "paying salaries", "training", "retirement"]], ["Performance appraisal means", ["reviewing an employee's work", "hiring", "advertising", "budgeting"]],
   ["Attrition means", ["employees leaving", "new joiners", "a salary hike", "holidays"]], ["KRA stands for", ["Key Result Area", "Key Rate Account", "Known Risk Area", "Key Role Assignment"]], ["An exit interview happens", ["when an employee leaves", "on the first day", "at promotion", "at hiring"]]]),
 (5, "Financial management", "Workplace situation", [["Time value of money", "₹100 today is worth more than ₹100 next year.", "Future value = P (1 + r)ⁿ", "ಇಂದಿನ ಹಣದ ಮೌಲ್ಯ ಹೆಚ್ಚು"], ["Ratios", "Current ratio = current assets ÷ current liabilities.", "About 2 : 1 is usually safe", "ಅನುಪಾತಗಳು"]],
  [["Current ratio =", ["Current assets ÷ current liabilities", "Profit ÷ sales", "Sales ÷ assets", "Debt ÷ equity"]], ["Equity means", ["the owners' money in the business", "a loan", "a bill", "a tax"]], ["A dividend is", ["profit paid to shareholders", "a loan", "a salary", "a tax"]],
   ["Gross profit =", ["Sales − cost of goods sold", "Sales + cost", "Net profit − tax", "Assets − liabilities"]], ["₹1,000 at 10% for 1 year grows to", ["₹1,100", "₹1,010", "₹1,200", "₹1,000"]], ["The debt-equity ratio compares", ["borrowed money with owners' money", "sales growth", "stock levels", "salaries"]]]),
 (6, "Business economics", "Interview Q", [["Demand and supply", "Price up → demand down; price up → supply up.", "Law of demand", "ಬೇಡಿಕೆ / ಪೂರೈಕೆ"], ["Inflation and GDP", "Inflation = prices rising. GDP = value of all goods and services made in a year.", "CPI · GDP", "ಬೆಲೆ ಏರಿಕೆ, GDP"]],
  [["When price rises, demand usually", ["falls", "rises", "stays the same", "doubles"]], ["Inflation means", ["a general rise in prices", "a fall in prices", "more jobs", "more exports"]], ["GDP measures", ["the value of goods and services produced", "government debt", "gold reserves", "population"]],
   ["A market with one seller", ["Monopoly", "Perfect competition", "Oligopoly", "Duopoly"]], ["The RBI controls", ["money supply and interest rates", "GST rates", "school fees", "film tickets"]], ["A few big sellers (like mobile networks)", ["Oligopoly", "Monopoly", "Perfect competition", "Barter"]]]),
 (7, "Organisational behaviour", "HR / technical interview", [["Motivation", "Maslow: needs from basic to self-actualisation. Herzberg: pay is hygiene, recognition motivates.", "Pay = hygiene · praise = motivator", "ಪ್ರೇರಣೆ"], ["Leadership styles", "Autocratic (boss decides), Democratic (team is asked), Laissez-faire (team is free).", "Pick the style for the situation", "ನಾಯಕತ್ವ ಶೈಲಿ"]],
  [["A leader who asks the team before deciding", ["Democratic", "Autocratic", "Laissez-faire", "Absent"]], ["Top of Maslow's hierarchy", ["Self-actualisation", "Safety", "Food", "Belonging"]], ["In Herzberg's theory, salary is a", ["hygiene factor", "motivator", "leadership style", "punishment"]],
   ["Team stages: forming, storming, norming and", ["performing", "sleeping", "firing", "hiring"]], ["Conflict is best handled by", ["discussing calmly to find a solution", "ignoring it", "shouting", "quitting"]], ["Organisational culture is", ["shared values and behaviour at work", "the office building", "the salary scale", "a product"]]]),
 (8, "Entrepreneurship", "Workplace situation", [["Startup basics", "Idea → MVP (a simple first version) → customers → funding → growth.", "MVP = test with real users", "ಸ್ಟಾರ್ಟ್‌ಅಪ್ ಹಂತಗಳು"], ["Business plan", "Problem, solution, customers, costs, revenue.", "A one-page lean canvas", "ವ್ಯವಹಾರ ಯೋಜನೆ"]],
  [["MVP stands for", ["Minimum Viable Product", "Maximum Value Price", "Most Valuable Person", "Market Value Plan"]], ["Money from an early private investor", ["Angel investment", "Bank FD", "Salary", "Tax refund"]], ["Break-even tells an entrepreneur", ["when costs are covered", "the brand name", "the office location", "staff names"]],
   ["Government programme for startups", ["Startup India", "Swachh Bharat", "Make a Wish", "Digital Ration"]], ["A business owned by one person", ["Sole proprietorship", "Partnership", "Company", "Cooperative"]], ["Bootstrapping means", ["starting with your own money", "a big bank loan", "selling shares", "a government grant"]]]),
 (9, "Communication & ethics", "Interview Q", [["7 Cs", "Clear, Concise, Concrete, Correct, Coherent, Complete, Courteous.", "Clear + short + polite", "ಸಂವಹನದ 7 Cs"], ["Ethics at work", "Honesty, confidentiality, no bribes, respect for all.", "Say no to gifts that buy favours", "ಕೆಲಸದ ನೈತಿಕತೆ"]],
  [["A memo is", ["a short internal office message", "a bill", "a contract", "a tax form"]], ["Best email subject", ["Meeting moved to 3 pm Tuesday", "Hi", "Important!!!", "(no subject)"]], ["Sharing client data with friends is", ["unethical", "fine", "smart", "marketing"]],
   ["The 'grapevine' at work is", ["informal office talk", "a fruit", "a report", "a meeting"]], ["Non-verbal communication includes", ["body language", "emails", "letters", "reports"]], ["Taking a gift to favour a supplier is", ["a conflict of interest", "teamwork", "branding", "motivation"]]])])
BCOM = TECH([
 (3, "Final accounts", "Interview Q", [["Trading and P&L", "Trading account → gross profit. P&L account → net profit.", "Sales − COGS = GP · GP − expenses = NP", "ವ್ಯಾಪಾರ ಮತ್ತು ಲಾಭ-ನಷ್ಟ ಖಾತೆ"], ["Balance sheet", "Assets on one side, capital and liabilities on the other; totals match.", "Assets = Capital + Liabilities", "ಆಸ್ತಿ = ಬಂಡವಾಳ + ಹೊಣೆ"]],
  [["Gross profit is found in the", ["Trading account", "Balance sheet", "Cash book", "Journal"]], ["Sales ₹50,000, cost of goods sold ₹35,000. Gross profit?", ["₹15,000", "₹85,000", "₹35,000", "₹50,000"]], ["Rent paid goes to the", ["P&L account", "assets side", "Trading account credit", "Capital account"]],
   ["Closing stock appears in", ["the Trading account and the Balance sheet", "only the Cash book", "only the P&L account", "nowhere"]], ["Outstanding salary is", ["a liability", "an asset", "an income", "capital"]], ["Machinery is shown under", ["fixed assets", "current liabilities", "incomes", "expenses"]]]),
 (4, "Banking", "Workplace situation", [["Accounts", "Savings (people), Current (business), FD (fixed time, more interest).", "SB · CA · FD · RD", "ಬ್ಯಾಂಕ್ ಖಾತೆಗಳು"], ["Payments", "NEFT (batches), RTGS (big, instant), IMPS / UPI (24×7, instant).", "UPI = instant phone payment", "ಹಣ ವರ್ಗಾವಣೆ"]],
  [["Account for a business", ["Current account", "Savings account", "FD only", "PPF"]], ["RTGS is used for", ["large instant transfers", "small cash", "cheques only", "foreign coins"]], ["An IFSC code identifies", ["a bank branch", "a customer", "a cheque", "a tax"]],
   ["India's central bank", ["RBI", "SBI", "SEBI", "NABARD"]], ["KYC means", ["Know Your Customer", "Keep Your Cash", "Know Your Card", "Key Yearly Charge"]], ["The repo rate is", ["the rate at which RBI lends to banks", "savings interest", "the GST rate", "a loan EMI"]]]),
 (5, "Income tax basics", "Interview Q", [["PAN and ITR", "PAN = your tax ID. ITR = the yearly income tax return.", "PAN = 10 characters", "PAN, ITR"], ["Old vs new regime", "New regime: lower rates, fewer deductions. Choose the one with less tax.", "Compare both every year", "ಹಳೆ / ಹೊಸ ವಿಧಾನ"]],
  [["A PAN has how many characters?", ["10", "12", "15", "8"]], ["TDS means", ["Tax Deducted at Source", "Tax Due Soon", "Total Deposit Sum", "Tax Deposit Slip"]], ["India's financial year", ["1 April – 31 March", "1 January – 31 December", "1 July – 30 June", "1 October – 30 September"]],
   ["Section 80C gives deductions for", ["PPF, LIC, ELSS", "GST refunds", "bank loans", "salary hikes"]], ["An ITR is filed to", ["report income and tax to the government", "open a bank account", "register for GST", "apply for a PAN"]], ["Form 16 is issued by the", ["employer", "bank", "RBI", "college"]]]),
 (6, "Cost accounting", "Workplace situation", [["Fixed vs variable", "Fixed cost stays the same (rent). Variable cost changes with output (raw material).", "Total = fixed + variable", "ಸ್ಥಿರ / ಬದಲಾಗುವ ವೆಚ್ಚ"], ["Contribution", "Contribution = sales − variable cost.", "BEP units = fixed cost ÷ contribution per unit", "ಕೊಡುಗೆ"]],
  [["Factory rent is a", ["fixed cost", "variable cost", "revenue", "profit"]], ["Raw material cost is a", ["variable cost", "fixed cost", "capital", "income"]], ["Price ₹100 per unit, variable cost ₹60. Contribution per unit?", ["₹40", "₹160", "₹60", "₹100"]],
   ["Fixed cost ₹40,000, contribution ₹40 per unit. Break-even units?", ["1,000", "400", "4,000", "100"]], ["Prime cost =", ["direct material + direct labour + direct expenses", "total cost + profit", "factory overheads only", "sales − cost"]], ["Overheads are", ["indirect costs", "direct material", "profit", "sales"]]]),
 (7, "Company accounts & shares", "Interview Q", [["Shares", "Equity shareholders own the company; preference shareholders get a fixed dividend first.", "Face value · premium · discount", "ಷೇರುಗಳು"], ["Debentures", "A loan to the company with fixed interest.", "Debenture holders = lenders", "ಡಿಬೆಂಚರ್ = ಸಾಲ"]],
  [["Equity shareholders are the company's", ["owners", "lenders", "customers", "auditors"]], ["Debenture holders are", ["lenders to the company", "owners", "employees", "directors only"]], ["Issuing shares above face value is", ["issue at a premium", "issue at par", "issue at a discount", "a buy-back"]],
   ["Stock market regulator in India", ["SEBI", "RBI", "IRDAI", "NITI Aayog"]], ["Free shares given to existing shareholders", ["Bonus shares", "Rights shares", "Sweat equity", "An IPO"]], ["IPO stands for", ["Initial Public Offering", "Indian Price Order", "Internal Profit Option", "Interest Paid Once"]]]),
 (8, "Auditing", "Interview Q", [["What an audit is", "An independent check that the accounts are true and fair.", "Vouching · verification · report", "ಲೆಕ್ಕಪರಿಶೋಧನೆ"], ["Vouching", "Checking each entry against bills and receipts.", "Entry ↔ voucher", "ವೌಚರ್ ಪರಿಶೀಲನೆ"]],
  [["An audit checks that accounts are", ["true and fair", "profitable", "secret", "taxed"]], ["Vouching means", ["checking entries with documents", "writing cheques", "paying tax", "hiring"]], ["A company's auditors are appointed by", ["shareholders at the AGM", "the bank", "customers", "the CEO alone"]],
   ["Internal audit is done by", ["the company's own staff", "only the government", "customers", "the RBI"]], ["A 'qualified' audit report means", ["the auditor has some reservations", "everything is perfect", "the auditor has a degree", "no audit was done"]], ["Errors that cancel each other out", ["Compensating errors", "Errors of omission", "Errors of principle", "Audit fees"]]]),
 (9, "Excel for accounts", "Workplace situation", [["Must-know formulas", "SUM, AVERAGE, IF, VLOOKUP / XLOOKUP, SUMIF.", "=SUMIF(A:A,\"Rent\",B:B)", "ಮುಖ್ಯ ಸೂತ್ರಗಳು"], ["Absolute reference", "$A$1 stays the same when you copy the formula.", "=B2*$E$1", "$ ಚಿಹ್ನೆ"]],
  [["Look up a value in a table by its key", ["VLOOKUP", "SUM", "LEN", "NOW"]], ["=IF(B2>=35,\"Pass\",\"Fail\") with B2 = 40", ["Pass", "Fail", "40", "Error"]], ["$A$1 is", ["an absolute reference", "a currency", "an error", "a chart"]],
   ["Add only the 'Rent' rows", ["SUMIF", "COUNT", "MAX", "ROUND"]], ["=ROUND(12.567, 1)", ["12.6", "12.5", "13", "12.57"]], ["Keyboard shortcut to save", ["Ctrl + S", "Ctrl + P", "Ctrl + Z", "Ctrl + X"]]])])

# ── JAPANESE 3-9 ──
KANA = {3: ("Hiragana: S row", [("さ", "sa", "ಸ"), ("し", "shi", "ಶಿ"), ("す", "su", "ಸು"), ("せ", "se", "ಸೆ"), ("そ", "so", "ಸೊ")]),
        4: ("Hiragana: T row", [("た", "ta", "ತ"), ("ち", "chi", "ಚಿ"), ("つ", "tsu", "ತ್ಸು"), ("て", "te", "ತೆ"), ("と", "to", "ತೊ")]),
        5: ("Hiragana: N and H rows", [("な", "na", "ನ"), ("に", "ni", "ನಿ"), ("ぬ", "nu", "ನು"), ("ね", "ne", "ನೆ"), ("の", "no", "ನೊ"), ("は", "ha", "ಹ"), ("ひ", "hi", "ಹಿ"), ("ふ", "fu", "ಫು"), ("へ", "he", "ಹೆ"), ("ほ", "ho", "ಹೊ")]),
        6: ("Hiragana: M, Y, R, W rows", [("ま", "ma", "ಮ"), ("み", "mi", "ಮಿ"), ("む", "mu", "ಮು"), ("め", "me", "ಮೆ"), ("も", "mo", "ಮೊ"), ("や", "ya", "ಯ"), ("ゆ", "yu", "ಯು"), ("よ", "yo", "ಯೊ"), ("ら", "ra", "ರ"), ("り", "ri", "ರಿ"), ("る", "ru", "ರು"), ("れ", "re", "ರೆ"), ("ろ", "ro", "ರೊ"), ("わ", "wa", "ವ"), ("ん", "n", "ನ್")]),
        7: ("Katakana: vowels and K", [("ア", "a", "ಅ"), ("イ", "i", "ಇ"), ("ウ", "u", "ಉ"), ("エ", "e", "ಎ"), ("オ", "o", "ಒ"), ("カ", "ka", "ಕ"), ("キ", "ki", "ಕಿ"), ("ク", "ku", "ಕು"), ("ケ", "ke", "ಕೆ"), ("コ", "ko", "ಕೊ")])}
def kana(n, r):
    name, row = KANA[n]; out = []
    for k, ro, kn in r.sample(row, 4):
        others = [x[1] for x in row if x[1] != ro]; out.append(Q(f"{k} is read as", [ro] + r.sample(others, 3), f"{k} = {ro} = {kn}."))
    for k, ro, kn in r.sample(row, 2):
        others = [x[0] for x in row if x[0] != k]; out.append(Q(f"Which one is {kn} ({ro})?", [k] + r.sample(others, 3), f"{k} = {ro} = {kn}."))
    cards = [C(name, "Each letter is one sound, like Kannada.", "  ".join(f"{k} {ro}" for k, ro, _ in row[:5]), " ".join(f"{k}={kn}" for k, _, kn in row[:5]))]
    if len(row) > 5: cards.append(C(name + " (more)", "Say each one aloud 3 times.", "  ".join(f"{k} {ro}" for k, ro, _ in row[5:]), " ".join(f"{k}={kn}" for k, _, kn in row[5:])))
    else: cards.append(C("Practise", "Cover the romaji and read the letters aloud.", "  ".join(k for k, _, _ in row), "ಜೋರಾಗಿ ಓದಿ"))
    if n == 7: cards.insert(0, C("Katakana", "The second Japanese alphabet, used for foreign words and names.", "コーヒー (koohii) = coffee", "ವಿದೇಶಿ ಪದಗಳಿಗೆ ಕಟಕಾನಾ"))
    return name, cards, out
JP_HAND = [(8, "Numbers", [C("1 to 5", "いち ichi 1 · に ni 2 · さん san 3 · よん / し yon / shi 4 · ご go 5", "1 2 3 4 5", "ಇಚಿ · ನಿ · ಸನ್ · ಯೊನ್ · ಗೊ"), C("6 to 10", "ろく roku 6 · なな / しち nana / shichi 7 · はち hachi 8 · きゅう kyuu 9 · じゅう juu 10", "20 = にじゅう (ni-juu)", "ರೊಕು · ನನ · ಹಚಿ · ಕ್ಯೂ · ಜೂ")],
            [["いち means", ["1", "2", "3", "10"]], ["さん means", ["3", "1", "8", "6"]], ["ご means", ["5", "9", "4", "7"]], ["じゅう means", ["10", "5", "100", "1"]], ["7 in Japanese", ["なな", "はち", "きゅう", "よん"], "なな (nana) or しち (shichi)."], ["にじゅう means", ["20", "12", "2", "200"], "に (2) × じゅう (10)."]]),
           (9, "Greetings & self-introduction", [C("Greetings", "おはよう ohayou (morning) · こんにちは konnichiwa (hello) · こんばんは konbanwa (evening)", "Bow a little when you greet", "ಶುಭಾಶಯಗಳು"), C("Introduce yourself", "はじめまして。わたしは アナンヤ です。よろしく おねがいします。", "Hajimemashite. Watashi wa Ananya desu. Yoroshiku onegaishimasu.", "ನನ್ನ ಹೆಸರು ಅನನ್ಯ. ಭೇಟಿಯಾಗಿ ಸಂತೋಷ.")],
            [["こんにちは means", ["Hello", "Good night", "Thank you", "Sorry"]], ["'Good morning' in Japanese", ["おはよう", "こんばんは", "さようなら", "ありがとう"]], ["わたしは … です means", ["I am …", "You are …", "He is …", "They are …"]],
             ["さようなら means", ["Goodbye", "Hello", "Please", "Yes"]], ["'Nice to meet you'", ["はじめまして", "すみません", "いいえ", "はい"]], ["ありがとう means", ["Thank you", "Excuse me", "Good evening", "No"]]])]

PRO = lambda t: {"n": 10, "name": "PRO test", "tag": "Mixed from levels 1-9", "pro": True, "cards": [C("PRO test", "12 mixed questions from all levels of this track. Pass 80% for the 👑 gold certificate.", "Revise weak levels first", "ಎಲ್ಲ ಹಂತಗಳ ಮಿಶ್ರ ಪ್ರಶ್ನೆಗಳು")], "qs": []}
def put(tid, levels):
    t = next(x for x in B["tracks"] if x["id"] == tid)
    t["levels"] = [l for l in t["levels"] if l["n"] < 3] + levels + [PRO(tid)]
put("quant", [L(n, nm, tg, cards, f(R(f"quant{n}"))) for n, nm, tg, f, cards in QUANT])
put("reason", [L(n, nm, tg, cards, qs if qs else (clock if n == 8 else rank)(R(f"reason{n}"))) for n, nm, tg, cards, qs in REASON])
put("verbal", [L(*x) for x in VERBAL]); put("english", [L(*x) for x in ENGLISH])
put("bca", [L(*x) for x in BCA]); put("bba", [L(*x) for x in BBA]); put("bcom", [L(*x) for x in BCOM])
jl = []
for n in range(3, 8): nm, cards, qs = kana(n, R(f"jp{n}")); jl.append(L(n, nm, "JLPT N5", cards, qs))
for n, nm, cards, rows in JP_HAND: jl.append(L(n, nm, "JLPT N5", cards, H(rows)))
put("japanese", jl)
B["mocks"] = [{"id": "tcs", "name": "TCS NQT pattern mock", "min": 40, "sec": [["Numerical ability", "quant", 10], ["Reasoning", "reason", 10], ["Verbal ability", "verbal", 10]]},
              {"id": "infosys", "name": "Infosys pattern mock", "min": 35, "sec": [["Quantitative", "quant", 10], ["Logical reasoning", "reason", 12], ["Verbal", "verbal", 8]]},
              {"id": "wipro", "name": "Wipro pattern mock", "min": 30, "sec": [["Quantitative", "quant", 10], ["Logical", "reason", 10], ["Verbal", "verbal", 10]]},
              {"id": "accenture", "name": "Accenture pattern mock", "min": 35, "sec": [["Quantitative", "quant", 8], ["Reasoning", "reason", 12], ["Verbal", "verbal", 10]]},
              {"id": "amcat", "name": "AMCAT pattern mock", "min": 35, "sec": [["Quantitative", "quant", 10], ["Logical", "reason", 10], ["English", "verbal", 10]]}]
B["paths"] = [   # 19-Oct-2026 (BUILD-ALL step 5): "Prepare for <company>" - levels + the company mock; "tech" = the learner's own course
    {"co": "tcs", "name": "TCS NQT", "steps": [{"t": "quant", "n": 3}, {"t": "reason", "n": 3}, {"t": "verbal", "n": 2}, {"t": "english", "n": 3}, {"mock": "tcs", "p": 70}]},
    {"co": "infosys", "name": "Infosys", "steps": [{"t": "quant", "n": 3}, {"t": "reason", "n": 4}, {"t": "verbal", "n": 3}, {"t": "english", "n": 3}, {"mock": "infosys", "p": 70}]},
    {"co": "wipro", "name": "Wipro", "steps": [{"t": "quant", "n": 2}, {"t": "reason", "n": 3}, {"t": "verbal", "n": 3}, {"t": "tech", "n": 2}, {"mock": "wipro", "p": 65}]},
    {"co": "accenture", "name": "Accenture", "steps": [{"t": "reason", "n": 4}, {"t": "quant", "n": 2}, {"t": "verbal", "n": 3}, {"t": "english", "n": 3}, {"mock": "accenture", "p": 70}]},
    {"co": "amcat", "name": "AMCAT", "steps": [{"t": "quant", "n": 3}, {"t": "reason", "n": 3}, {"t": "english", "n": 4}, {"t": "tech", "n": 2}, {"mock": "amcat", "p": 70}]}]
B["mockNote"] = "Practice tests in the style of these companies' online tests (same sections and timing). The questions are Davan's own, not copied from real papers."
# ids, checks, seeded shuffle (the widget shows options in this order)
n_q = 0
for t in B["tracks"]:
    for l in t["levels"]:
        for i, q in enumerate(l["qs"]):
            q["id"] = f"{t['id']}{l['n']}_{i + 1}"; assert len(set(q["o"])) == len(q["o"]) == 4, (q["id"], q["o"]); assert 0 <= q["a"] < 4
            right = q["o"][q["a"]]; rr = random.Random(int(hashlib.md5(q["id"].encode()).hexdigest()[:8], 16)); rr.shuffle(q["o"]); q["a"] = q["o"].index(right); n_q += 1
B["v"] = 2
json.dump(B, open(F, "w"), ensure_ascii=False, separators=(",", ":"))
print(n_q, "questions,", sum(len(t["levels"]) for t in B["tracks"]), "levels,", os.path.getsize(F) // 1024, "KB")
