.pragma library
// Calculatrice de la recherche : analyseur descendant récursif (pas d'eval).
// Grammaire : expr = terme (('+'|'-') terme)* ; terme = facteur (('*'|'×'|'/'|'÷'|'%') facteur)* ;
// facteur = unaire ('^' facteur)? ; unaire = ('-'|'+') unaire | nombre | '(' expr ')'.
// Accepte la virgule décimale. Renvoie null si l'entrée n'est pas un calcul.

function evaluate(input) {
    const src = String(input).replace(/\s+/g, "").replace(/,/g, ".")
    if (!/^[0-9.+\-*/×÷%^()]+$/.test(src) || !/[+\-*/×÷%^]/.test(src.replace(/^[-+]/, "")))
        return null
    let pos = 0
    const peek = () => src[pos]
    function number() {
        const m = /^\d*\.?\d+(?:e[+-]?\d+)?/.exec(src.slice(pos))
        if (!m) throw new Error("nombre attendu")
        pos += m[0].length
        return parseFloat(m[0])
    }
    function unary() {
        if (peek() === "-") { pos++; return -unary() }
        if (peek() === "+") { pos++; return unary() }
        if (peek() === "(") {
            pos++
            const v = expr()
            if (peek() !== ")") throw new Error(") attendue")
            pos++
            return v
        }
        return number()
    }
    function factor() {
        const base = unary()
        if (peek() === "^") { pos++; return Math.pow(base, factor()) }
        return base
    }
    function term() {
        let v = factor()
        while ("*×/÷%".includes(peek())) {
            const op = src[pos++]
            const r = factor()
            v = op === "*" || op === "×" ? v * r : op === "%" ? v % r : v / r
        }
        return v
    }
    function expr() {
        let v = term()
        while (peek() === "+" || peek() === "-") v = src[pos++] === "+" ? v + term() : v - term()
        return v
    }
    try {
        const v = expr()
        if (pos !== src.length || !isFinite(v)) return null
        return Math.round(v * 1e10) / 1e10
    } catch (e) {
        return null
    }
}

function format(v) {
    return v.toLocaleString(Qt.locale(), "f", Math.abs(v - Math.round(v)) < 1e-10 ? 0 : 6).replace(/[.,]?0+$/, function (m) { return /[.,]/.test(m) ? "" : m })
}
