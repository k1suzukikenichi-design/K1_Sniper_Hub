import Foundation

// MARK: - 5分足ローソク足モデル

/// 5分足ローソク足データを表す値オブジェクト。
struct Candle5m {
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let timestamp: Date

    /// 実体の高値（Open/Close の大きい方）
    var bodyHigh: Double { max(open, close) }
    /// 実体の安値（Open/Close の小さい方）
    var bodyLow: Double { min(open, close) }
}

// MARK: - 狙撃判定結果

/// judgeSnipe() の各ステージ結果をまとめた構造体。
struct SnipeJudgement {
    /// 第3段階 (OB): 指定価格帯への到達
    let stage3_OBReached: Bool
    /// 第4段階 (ChoCh): 5分足実体での高値/安値更新
    let stage4_ChoCh: Bool
    /// ±3σ フィルター: 現在価格が統計的歪み域に到達しているか
    let sigmaFilterPassed: Bool

    /// 総合判定: 全ステージ + フィルターが揃った場合 true
    var snipeConditionMet: Bool {
        return stage3_OBReached && stage4_ChoCh && sigmaFilterPassed
    }
}

// MARK: - ExecutionJudge

/// FACTベースの実行判定コア（第3・第4ステージ + ±3σフィルター対応版）。
/// total_distortion_score は「日米金利差」「実需」「IMMポジション偏り」から算出された合成スコアを想定する。
struct ExecutionJudge {

    // MARK: Properties

    /// 日米金利差・実需・IMMポジションの歪みから算出された合成スコア。
    /// 0 付近がニュートラルで、値が大きいほどマーケットの「歪み」が強い状態を表す。
    let totalDistortionScore: Double

    /// 第3段階 (OB): 狙撃対象の価格帯上限。例: 160.00
    let obPriceHigh: Double

    /// 第3段階 (OB): 狙撃対象の価格帯下限。例: 158.45
    let obPriceLow: Double

    /// ±3σ判定用: 直近N本の終値から算出した平均値
    let priceMean: Double

    /// ±3σ判定用: 直近N本の終値から算出した標準偏差
    let priceSigma: Double

    // MARK: Initializers

    /// 全パラメータを指定するイニシャライザ。
    init(
        totalDistortionScore: Double,
        obPriceHigh: Double = 160.00,
        obPriceLow: Double = 158.45,
        priceMean: Double = 159.00,
        priceSigma: Double = 0.50
    ) {
        self.totalDistortionScore = totalDistortionScore
        self.obPriceHigh = obPriceHigh
        self.obPriceLow = obPriceLow
        self.priceMean = priceMean
        self.priceSigma = priceSigma
    }

    /// コンポーネントスコアから合成スコアを算出する簡易版イニシャライザ。
    /// - Parameters:
    ///   - interestDifferential: 日米金利差由来の歪みスコア
    ///   - realDemandScore: 実需（輸出入フローなど）由来の歪みスコア
    ///   - immPositionBiasScore: IMMポジションの偏り由来の歪みスコア
    init(
        interestDifferential: Double,
        realDemandScore: Double,
        immPositionBiasScore: Double,
        obPriceHigh: Double = 160.00,
        obPriceLow: Double = 158.45,
        priceMean: Double = 159.00,
        priceSigma: Double = 0.50
    ) {
        self.totalDistortionScore = interestDifferential + realDemandScore + immPositionBiasScore
        self.obPriceHigh = obPriceHigh
        self.obPriceLow = obPriceLow
        self.priceMean = priceMean
        self.priceSigma = priceSigma
    }

    // MARK: Stage 1 & 2: Distortion Score

    /// 14 Units の投入可否を判定する（第1・第2ステージ）。
    /// - Returns: total_distortion_score が 2.0 以上なら true（投入許可）
    func judgeAllow14Units() -> Bool {
        return totalDistortionScore >= 2.0
    }

    // MARK: Stage 3: OB Price Range

    /// 第3段階 (OB): 現在価格が指定の価格帯（obPriceLow〜obPriceHigh）内に到達しているか判定する。
    ///
    /// 例: obPriceLow = 158.45、obPriceHigh = 160.00 の場合、
    /// 現在価格が 158.45〜160.00 の範囲内であれば OB 到達と判断する。
    /// - Parameter currentPrice: 現在のレート
    /// - Returns: OB価格帯内なら true
    func judgeStage3_OBReached(currentPrice: Double) -> Bool {
        return currentPrice >= obPriceLow && currentPrice <= obPriceHigh
    }

    // MARK: Stage 4: ChoCh (Change of Character)

    /// 第4段階 (ChoCh): 5分足データにおける「実体での高値/安値更新」を検知する。
    ///
    /// **ショート狙い（direction = -1）の場合**:
    /// 直前N本の実体安値最小値を、最新足の実体安値が下回ったとき ChoCh 成立（下方向転換）。
    ///
    /// **ロング狙い（direction = 1）の場合**:
    /// 直前N本の実体高値最大値を、最新足の実体高値が上回ったとき ChoCh 成立（上方向転換）。
    ///
    /// - Parameters:
    ///   - candles: 5分足ローソク足の配列（古い順）。最低2本必要。
    ///   - direction: 1 = ロング狙い、-1 = ショート狙い
    /// - Returns: ChoCh が成立していれば true
    func judgeStage4_ChoCh(candles: [Candle5m], direction: Int = -1) -> Bool {
        guard candles.count >= 2 else { return false }

        let previous = candles.dropLast()
        let current = candles.last!

        let prevBodyHighMax = previous.map(\.bodyHigh).max() ?? 0
        let prevBodyLowMin  = previous.map(\.bodyLow).min() ?? Double.infinity

        if direction == -1 {
            // ショート: 最新足の実体安値が直前の実体安値最小値を割り込んだら ChoCh
            return current.bodyLow < prevBodyLowMin
        } else {
            // ロング: 最新足の実体高値が直前の実体高値最大値を超えたら ChoCh
            return current.bodyHigh > prevBodyHighMax
        }
    }

    // MARK: Filter: ±3σ

    /// ±3σ フィルター: 現在価格が平均 ± 3σ の範囲外（統計的歪み域）にあるか確認する。
    ///
    /// priceMean と priceSigma は呼び出し元で直近N本の終値から事前に計算して渡すことを想定する。
    /// - Parameter currentPrice: 現在のレート
    /// - Returns: |currentPrice − priceMean| > 3 × priceSigma なら true
    func isBeyond3Sigma(currentPrice: Double) -> Bool {
        guard priceSigma > 0 else { return false }
        let zScore = abs(currentPrice - priceMean) / priceSigma
        return zScore > 3.0
    }

    // MARK: Comprehensive Snipe Judgement

    /// 全ステージを総合評価し「狙撃条件合致」かどうかを返す。
    ///
    /// 合致条件（AND）:
    ///   1. total_distortion_score >= 2.0（第1・第2ステージ通過）
    ///   2. 現在価格が OB 価格帯内（第3ステージ）
    ///   3. 5分足で ChoCh 確認（第4ステージ）
    ///   4. ±3σ 超えフラグが true（フィルター）
    ///
    /// - Parameters:
    ///   - currentPrice: 現在のレート
    ///   - candles5m: 5分足ローソク足配列（古い順）
    ///   - direction: 1 = ロング、-1 = ショート
    /// - Returns: `SnipeJudgement` 構造体（各ステージの詳細 + 総合判定）
    func judgeSnipe(
        currentPrice: Double,
        candles5m: [Candle5m],
        direction: Int = -1
    ) -> SnipeJudgement {
        let stage3 = judgeAllow14Units() && judgeStage3_OBReached(currentPrice: currentPrice)
        let stage4 = judgeStage4_ChoCh(candles: candles5m, direction: direction)
        let sigma  = isBeyond3Sigma(currentPrice: currentPrice)

        return SnipeJudgement(
            stage3_OBReached: stage3,
            stage4_ChoCh: stage4,
            sigmaFilterPassed: sigma
        )
    }
}
