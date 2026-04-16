# A Short Note on Summation

We define the sum $S_n = \sum_{i=1}^{n} a_i$ for a finite sequence $a_1, a_2,
\ldots, a_n$. The average of the sequence is $\bar{a} = S_n / n$.

## Basic identities

For positive integers $n$, the following identities hold:

$$
\sum_{i=1}^{n} i = \frac{n(n+1)}{2}
$$

$$
\sum_{i=1}^{n} i^2 = \frac{n(n+1)(2n+1)}{6}
$$

$$
\sum_{i=1}^{n} i^3 = \left( \frac{n(n+1)}{2} \right)^2
$$

## Infinite series

The geometric series converges for $|r| < 1$:

$$
\sum_{k=0}^{\infty} r^k = \frac{1}{1-r}
$$

A surprising identity by Euler is

$$
\sum_{k=1}^{\infty} \frac{1}{k^2} = \frac{\pi^2}{6}.
$$

## Proof sketch

Consider $f(x) = \sin(x) / x$. The function has roots at $x = k\pi$ for
nonzero integer $k$. Expressing $f$ as an infinite product and comparing
coefficients gives the result.

Inline examples mixed into prose: the quantity $\sigma^2$ denotes variance,
$\mu$ denotes the mean, and we often write $Z = (X - \mu) / \sigma$.

## Fenced math

```math
\int_{-\infty}^{\infty} e^{-x^2} \, dx = \sqrt{\pi}
```

```math
\begin{aligned}
\nabla \cdot \mathbf{E} &= \rho / \varepsilon_0 \\
\nabla \cdot \mathbf{B} &= 0 \\
\nabla \times \mathbf{E} &= -\frac{\partial \mathbf{B}}{\partial t} \\
\nabla \times \mathbf{B} &= \mu_0 \mathbf{J} + \mu_0 \varepsilon_0 \frac{\partial \mathbf{E}}{\partial t}
\end{aligned}
```

A remark: the inline pairs $a=b$ and $x > y$ are technically math by our
detector because they start with letters; the currency form `costs $5` is
plain text, as are `$PATH` and `$HOME` shell references.
