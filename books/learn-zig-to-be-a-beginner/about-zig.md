---
title: "Zigの特徴"
free: true
---

# Zigの特徴

具体的な説明に入る前に、Zigの雰囲気と特徴を軽く眺めてみます。

公式ドキュメントでは、Zigの特徴について以下のように述べられています。

> **Robust**
>   Behavior is correct even for edge cases such as out of memory.
> **Optimal**
>   Write programs the best way they can behave and perform.
> **Reusable**
>   The same code works in many environments which have different constraints.
> **Maintainable**
>   Precisely communicate intent to the compiler and other programmers. The language imposes a low overhead to reading code and is resilient to changing requirements and environments.
>
> <https://ziglang.org/documentation/0.10.1/#toc-Introduction> より引用

また、Zigの特徴として、Zigのコンパイラ自体がZigで開発されています。
いわゆるセルフホストコンパイラですね。
本書でも、適宜Zigコンパイラのコードを含めて進めていくので、
興味のある方はそちらも読んでみると面白いかもしれません。

次の章から、特筆すべき点を取り上げつつ紹介します。

