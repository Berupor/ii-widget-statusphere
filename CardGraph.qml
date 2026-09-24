import qs.modules.common
import qs.modules.common.functions
import QtQuick

/**
 * A scalar tile's line/bar chart: monotone cubic through the line so it never
 * overshoots above a peak, area fill fading to transparent, an end dot on the
 * current value. "bars" trades the curve for thin rounded-top bars.
 */
Canvas {
    id: root

    required property list<real> values
    property color color: Appearance.colors.colPrimary
    property string mode: "line" // line | bars
    property real inset: 6
    property real lineWidth: 2

    onValuesChanged: root.requestPaint()
    onColorChanged: root.requestPaint()
    onModeChanged: root.requestPaint()
    onWidthChanged: root.requestPaint()
    onHeightChanged: root.requestPaint()

    // Fritsch-Carlson monotone cubic tangents: a plain Catmull-Rom spline can swing
    // above a local peak or below a local trough, which reads as fake data on a
    // metric graph.
    function monotoneTangents(xs, ys) {
        const n = xs.length;
        const d = [];
        for (let i = 0; i < n - 1; i++)
            d.push((ys[i + 1] - ys[i]) / (xs[i + 1] - xs[i]));
        const m = new Array(n);
        m[0] = d[0];
        m[n - 1] = d[n - 2];
        for (let i = 1; i < n - 1; i++) {
            if (d[i - 1] === 0 || d[i] === 0 || (d[i - 1] < 0) !== (d[i] < 0))
                m[i] = 0;
            else
                m[i] = (d[i - 1] + d[i]) / 2;
        }
        for (let i = 0; i < n - 1; i++) {
            if (d[i] === 0) {
                m[i] = 0;
                m[i + 1] = 0;
                continue;
            }
            const a = m[i] / d[i];
            const b = m[i + 1] / d[i];
            const s = a * a + b * b;
            if (s > 9) {
                const t = 3 / Math.sqrt(s);
                m[i] = t * a * d[i];
                m[i + 1] = t * b * d[i];
            }
        }
        return m;
    }

    function tracePath(ctx, xs, ys, m) {
        ctx.moveTo(xs[0], ys[0]);
        for (let i = 0; i < xs.length - 1; i++) {
            const dx = xs[i + 1] - xs[i];
            ctx.bezierCurveTo(xs[i] + dx / 3, ys[i] + m[i] * dx / 3, xs[i + 1] - dx / 3, ys[i + 1] - m[i + 1] * dx / 3, xs[i + 1], ys[i + 1]);
        }
    }

    function paintBars(ctx, xs, ys, bottom) {
        const n = xs.length;
        const step = n > 1 ? xs[1] - xs[0] : width;
        const barWidth = Math.max(2, step * 0.55);
        const radius = Math.min(barWidth / 2, 4);
        ctx.fillStyle = root.color;
        for (let i = 0; i < n; i++) {
            const left = xs[i] - barWidth / 2;
            const top = Math.min(ys[i], bottom - radius);
            ctx.beginPath();
            ctx.moveTo(left, bottom);
            ctx.lineTo(left, top + radius);
            ctx.arcTo(left, top, left + radius, top, radius);
            ctx.lineTo(left + barWidth - radius, top);
            ctx.arcTo(left + barWidth, top, left + barWidth, top + radius, radius);
            ctx.lineTo(left + barWidth, bottom);
            ctx.closePath();
            ctx.fill();
        }
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (!values || values.length < 2)
            return;

        const left = root.inset, right = Math.max(root.inset, width - root.inset);
        const top = root.inset, bottom = Math.max(root.inset, height - root.inset);
        const n = values.length;
        const xs = values.map((v, i) => left + (right - left) * i / (n - 1));
        const ys = values.map(v => bottom - Math.min(1, Math.max(0, v)) * (bottom - top));

        if (root.mode === "bars") {
            root.paintBars(ctx, xs, ys, bottom);
            return;
        }

        const m = root.monotoneTangents(xs, ys);

        ctx.beginPath();
        root.tracePath(ctx, xs, ys, m);
        ctx.lineTo(xs[n - 1], bottom);
        ctx.lineTo(xs[0], bottom);
        ctx.closePath();
        const gradient = ctx.createLinearGradient(0, top, 0, bottom);
        gradient.addColorStop(0, ColorUtils.transparentize(root.color, 0.45));
        gradient.addColorStop(1, ColorUtils.transparentize(root.color, 1));
        ctx.fillStyle = gradient;
        ctx.fill();

        ctx.beginPath();
        root.tracePath(ctx, xs, ys, m);
        ctx.strokeStyle = root.color;
        ctx.lineWidth = root.lineWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.stroke();

        ctx.beginPath();
        ctx.arc(xs[n - 1], ys[n - 1], root.lineWidth * 1.6, 0, Math.PI * 2);
        ctx.fillStyle = root.color;
        ctx.fill();
    }
}
