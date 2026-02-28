import Foundation

/// FACTベースの実行判定コア。
/// total_distortion_score は「日米金利差」「実需」「IMMポジション偏り」から算出された合成スコアを想定する。
struct ExecutionJudge {
    
    /// 日米金利差・実需・IMMポジションの歪みから算出された合成スコア。
    /// 0 付近がニュートラルで、値が大きいほどマーケットの「歪み」が強い状態を表すことを想定する。
    let totalDistortionScore: Double
    
    /// 既に算出済みの total_distortion_score から初期化するためのイニシャライザ。
    init(totalDistortionScore: Double) {
        self.totalDistortionScore = totalDistortionScore
    }
    
    /// コンポーネントスコアから合成スコアを算出する簡易版イニシャライザ。
    /// - Parameters:
    ///   - interestDifferential: 日米金利差由来の歪みスコア
    ///   - realDemandScore: 実需（輸出入フローなど）由来の歪みスコア
    ///   - immPositionBiasScore: IMMポジションの偏り由来の歪みスコア
    init(
        interestDifferential: Double,
        realDemandScore: Double,
        immPositionBiasScore: Double
    ) {
        self.totalDistortionScore = interestDifferential + realDemandScore + immPositionBiasScore
    }
    
    /// 14 Units の投入可否を判定する。
    /// - Returns: total_distortion_score が 2.0 以上なら true（投入許可）、それ未満なら false（投入禁止）。
    func judgeAllow14Units() -> Bool {
        return totalDistortionScore >= 2.0
    }
}

