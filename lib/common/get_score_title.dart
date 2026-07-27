enum ScoreType { sugar, respiratory, liver, gut }

String getScoreTitle({
   bool isCorporate =false,
  required ScoreType score,
}) {
  const corporateTitles = {
    ScoreType.sugar: "Energy Utilisation Score",
    ScoreType.respiratory: "Breathing Efficiency Score",
    ScoreType.liver: "Metabolic Load Score",
    ScoreType.gut: "Digestive Balance Score",
  };

  const consumerTitles = {
    ScoreType.sugar: "Sugar Score",
    ScoreType.respiratory: "Respiratory Score",
    ScoreType.liver: "Liver Stress Score",
    ScoreType.gut: "Gut Fermentation Score",
  };

  return (isCorporate ? corporateTitles : consumerTitles)[score] ?? "Unknown";
}
