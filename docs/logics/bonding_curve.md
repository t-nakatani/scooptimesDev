以下では、スマートコントラクト内に書かれている二つの関数

- **`getTokenIn(ethAmount)`**: 「追加で `ethAmount` 分の ETH を支払うと、増分として何トークン手に入るか」  
- **`getEthIn(tokenAmount)`**: 「`tokenAmount` 分のトークンを売却すると、増分として何 ETH 返ってくるか」

について、式中の各項が**何を意味するのか**をできるだけ省略せずに解説します。

---

# ボンディングカーブの前提

まず、根本的な前提として、このコントラクトでは **ボンディングカーブ**（Bonding Curve）という仕組みにより、トークンの買い値・売り値が決定されます。ボンディングカーブとは、

> 「トークンの発行量あるいは販売量が増加していくにつれ、1 トークンあたりの価格がルールに応じて徐々に変化する（多くの場合、上昇する）仕組み」

のことです。ここでは、下記のような**指数関数**をベースとした価格モデルを使っています。

---

# 記号・変数の意味

以下、両方の式で登場する主な変数を整理します。

1. **\( k \)**  
   - 初期価格を調整するための定数（スケールファクター）  
   - 価格水準が全体的に「高くなる・低くなる」をコントロールする役割を担います。

2. **\( \alpha \)（アルファ）**  
   - ボンディングカーブの**傾き（急さ）**を示す定数  
   - 数値が大きいほど、価格がより急速に上昇（あるいは下降）するようになります。

3. **\( \text{totalRaised} \)**  
   - いままでに購入によって集まった ETH の合計額  
   - 追加購入が起きれば増え、売却が起きれば（返却する ETH 分だけ）減っていきます。

4. **\( \text{tokensSold} \)**  
   - いままでに発行（購入）されたトークンの合計量（売却されれば、その分だけ回収されるので減る）  
   - 「現在流通しているトークン数」に近いイメージの量。

5. **\(\exp(x) = e^x\)**  
   - 自然指数関数。\( e \approx 2.718281828...\) を底とした指数関数です。  
   - 値が急速に増加・減少する挙動を表現するのに使われます。

6. **\(\ln(x)\)**  
   - 自然対数。上記の指数関数 \(\exp(\cdot)\) と逆の計算を行う関数です。  
   - \(\exp(\ln(x)) = x\) のように、一方が他方の逆関数になっています。

いずれの式も、「**（購入・売却）前の状態**」と「**（購入・売却）後の状態**」の**差分**を計算して、「追加で何トークン得られるのか」「何 ETH 戻ってくるのか」を求める構造です。

---

# 1. 購入トークン数を計算する `getTokenIn(ethAmount)`

## コード部分

```solidity
function getTokenIn(uint256 ethAmount) public view returns (uint256) {
    UD60x18 totalRaisedFixed = ud(totalRaised);
    UD60x18 ethAmountFixed   = ud(ethAmount);
    UD60x18 kFixed           = ud(k);
    UD60x18 alphaFixed       = ud(alpha);

    // 1. 追加購入 "前" のトークン総量
    UD60x18 tokensBefore =
        totalRaisedFixed
            .div(kFixed)
            .add(ud(1e18))   // 1e18は PRBMath の固定小数点対応
            .ln()           // 自然対数を取る
            .div(alphaFixed);

    // 2. 追加購入 "後" のトークン総量
    UD60x18 tokensAfter =
        totalRaisedFixed
            .add(ethAmountFixed)  // 今回の購入分を足す
            .div(kFixed)
            .add(ud(1e18))
            .ln()
            .div(alphaFixed);

    // 3. 差分 = (後) - (前) が、今回購入で受け取れるトークン数
    return tokensAfter.sub(tokensBefore).unwrap();
}
```

## 数式

契約内での計算を、変数名や演算に合わせて**連続的な式**に書き下すと、下記のようになります。（説明のため小数や型は単純化して表現します）

\[
\begin{aligned}
&\text{(1) } \text{tokensBefore}
= \frac{ \ln\Bigl(\tfrac{\text{totalRaised}}{k} + 1\Bigr)}{\alpha},\\
\\
&\text{(2) } \text{tokensAfter}
= \frac{ \ln\Bigl(\tfrac{\text{totalRaised} + \text{ethAmount}}{k} + 1\Bigr)}{\alpha},\\
\\
&\text{(3) } \Delta \text{token} \;=\;
 \text{tokensAfter} \;-\; \text{tokensBefore}.
\end{aligned}
\]

### 意味すること
1. **\(\ln\Bigl(\frac{\text{totalRaised}}{k} + 1\Bigr)\)**  
   - 「すでに集まった ETH (\(\text{totalRaised}\))」を、スケール係数 \(k\) で割って正規化し、「+1」している箇所により、開始時点では\(\ln(1) = 0\)になるように調整しています。  
   - 対数 \(\ln(\dots)\) を取ることで、**販売が進むほど**、追加購入による「もらえるトークン数の増分」が**徐々に減っていく**ように設定しています。

2. **\(\alpha\) で割る**  
   - \(\alpha\) が大きいほど、対数の値を小さく割る（つまり値を大きくする）効果があり、価格の上昇カーブを急にします。  
   - \(\alpha\) が小さいと、緩やかなカーブになります。

3. **`\Delta token = tokensAfter - tokensBefore`**  
   - **「追加で `ethAmount` 分の ETH を支払った結果、トークン総量がどれだけ増えたか」**を差分として求めています。  
   - 「総量」そのものを返すのではなく、あくまで増分がユーザーの購入分となります。

---

# 2. 売却 ETH 額を計算する `getEthIn(tokenAmount)`

## コード部分

```solidity
function getEthIn(uint256 tokenAmount) public view returns (uint256) {
    UD60x18 soldTokensFixed  = ud(tokensSold);
    UD60x18 tokenAmountFixed = ud(tokenAmount);
    UD60x18 kFixed           = ud(k);
    UD60x18 alphaFixed       = ud(alpha);

    // 1. 売却 "前" の状態で理論的に必要なETH量 = k * (exp(alpha * tokensSold) - 1)
    UD60x18 ethBefore =
        kFixed
            .mul(alphaFixed.mul(soldTokensFixed).exp())
            .sub(kFixed);

    // 2. 売却 "後" の状態で理論的に必要なETH量 = k * (exp(alpha * (tokensSold - tokenAmount)) - 1)
    UD60x18 ethAfter =
        kFixed
            .mul(
                alphaFixed
                  .mul(soldTokensFixed.sub(tokenAmountFixed))
                  .exp()
            )
            .sub(kFixed);

    // 3. 差分 = (前) - (後) が、今回売却で戻ってくるETH
    return ethBefore.sub(ethAfter).unwrap();
}
```

## 数式

先ほどと同様に、計算を式で記述すると:

\[
\begin{aligned}
&\text{(1) } \text{ethBefore} 
= k \times \Bigl(\exp\bigl(\alpha \times \text{tokensSold}\bigr) - 1 \Bigr),\\
\\
&\text{(2) } \text{ethAfter}
= k \times \Bigl(\exp\bigl(\alpha \times (\text{tokensSold} - \text{tokenAmount})\bigr) - 1 \Bigr),\\
\\
&\text{(3) } \Delta \text{ETH} \;=\;
 \text{ethBefore} \;-\; \text{ethAfter}.
\end{aligned}
\]

### 意味すること

1. **\(\exp(\alpha \times \text{tokensSold})\)**  
   - 「いままで売り出された（購入された）トークンの総量」を、指数関数 \(\exp\) で評価したもの。  
   - 「トークンが多く売れている (= \(\text{tokensSold}\) が大きい)」状態だと、\(\exp(\alpha \times \dots)\) の値が非常に大きくなるため、結果として**価格が上昇**します。  
   - \(\alpha\) が大きいほど、増え方は一層急になります。

2. **\(k \times [\exp(\dots) - 1]\)**  
   - 初期状態 (\(\text{tokensSold} = 0\)) では \(\exp(0) = 1\) なので \(\exp(\dots) - 1 = 0\) になり、**初期時点の理論 ETH が 0** になるように調整しています。  
   - \(k\) を掛けることで、全体の価格水準をスケールさせています。

3. **`\Delta ETH = ethBefore - ethAfter`**  
   - 「売却前の理論上の ETH 総量」と「売却後の理論上の ETH 総量」の**差分**が、今回の売却によってユーザーに返される ETH（増分）になります。  
   - もし大量のトークンが売却されると、\(\text{tokensSold} - \text{tokenAmount}\) が小さくなるため、指数の値がグッと減り、**差分（返ってくる ETH）** が大きくなる仕組みです。

---

# なぜ「購入」と「売却」で式が対になっているのか？

- 購入時には、**対数関数** \(\ln(\cdot)\) が登場し、**「追加購入で得られるトークン数」**を計算しています。  
  - これは「ボンディングカーブ上の**コスト関数**」を逆から見た式にあたります。購入で増える総コストの差分を対数で求め、そこから増分トークンを逆算しているイメージです。

- 売却時には、**指数関数** \(\exp(\cdot)\) が登場し、**「トークンを手放すことで得られる ETH」**を計算しています。  
  - これは「トークン流通量を指数関数で評価したとき、その前後の ETH の理論量の差」を返すことで、売り手が受け取る ETH を決めるしくみです。

要するに、  
> **購入 (GetTokenIn)** は「\(\ln\) によって『今の調達額→トークン』への逆変換」をしてトークン増分を出す。  
> **売却 (GetEthIn)** は「\(\exp\) によって『今のトークン流通量→理論的 ETH コスト』を算出し、その差分を売り手に渡す」。

このように、**対数と指数**が**互いに逆関数**として噛み合うことで、

- 「流通量が増えれば価格が上がる」  
- 「売ればその価格差に応じた ETH が戻る」

という一貫性を保ったボンディングカーブが形成されているのです。

---

# まとめ: 本質的な理解

1. **スケール係数 \(k\)**  
   - ボンディングカーブの「基準価格」を設定するもの。  
   - \(k\) が大きいほど、曲線全体の価格水準が上がり、初期価格も高くなる。

2. **傾き係数 \(\alpha\)**  
   - ボンディングカーブの「急さ」を決めるもの。  
   - \(\alpha\) が大きいと、販売数や流通量の増加に対する価格上昇が急激になる。

3. **指数関数 \(\exp(\alpha \cdot T)\) と自然対数 \(\ln(\cdot)\)**  
   - \(\exp(\alpha \cdot T)\) は、トークンが増えていくほど値が急速に膨らむ性質を利用して、**「売却時に返す ETH の理論値」**を表現。  
   - \(\ln(\cdot)\) はその逆関数として、**「追加で支払う ETH から、増分トークンを逆算」**するときに使用。

4. **「前後の差」 = 売買による増減分**  
   - 価格やコストを**「積分的に管理」**しているため、買うときは「支払い前後のトークン総量の差」、売るときは「売却前後の理論 ETH 総量の差」が実際に動く量になる。  
   - このように、**「状態がどう変わったか」**を見ることで、売買のたびに正確なトークン量や ETH 額を算出できる。

---

# 最後に

- **最初にトークンを買った人は安い価格でたくさんトークンが得られる**。しかし多くの人が買っていくと \(\text{totalRaised}\) や \(\text{tokensSold}\) が増加し、指数・対数関数によって価格が高騰し、**追加購入で得られるトークン数は小さくなる**。  
- 売却する場合は、すでにたくさん買われて価格が上昇した状態ならば、**大きな量の ETH を受け取れる**ようになる。  
- こうした「**販売量（流通量）に応じた価格変動**」こそが、ボンディングカーブの本質です。  

本コントラクトでは、この仕組みを **指数関数と対数関数という“逆関数ペア”** で実装し、購入と売却を整合的に扱っています。式中の各項目が「購入前の総コスト」「購入後の総コスト」「売却前の理論値」「売却後の理論値」のようにペアをなしていることを意識すると、ボンディングカーブの根本的なメカニズムが理解しやすくなるはずです。