/**
 * Sensor Fusion Engine for Motorcycle Crash & Pothole Hazard Detection
 * Combines Accelerometer, Gyroscope, GPS Speed, and Phone Orientation.
 */

class SensorFusionService {
  /**
   * Evaluate a telemetry window for high confidence accident/impact.
   * @param {Object} telemetryData
   * @param {number} telemetryData.accelG - Peak Acceleration in G (1G = 9.81 m/s^2)
   * @param {number} telemetryData.gyroRadSec - Peak Gyroscope Angular Velocity in rad/s
   * @param {number} telemetryData.speedBeforeKmh - GPS speed before event (km/h)
   * @param {number} telemetryData.speedAfterKmh - GPS speed 1-2 sec after event (km/h)
   * @param {number} telemetryData.pitchDeg - Tilt angle pitch change
   * @param {number} telemetryData.rollDeg - Tilt angle roll change
   * @param {boolean} telemetryData.isRiderImmobile - No significant movement post impact
   * @param {string} sensitivity - 'low', 'medium', 'high'
   * @returns {Object} { isCrashDetected: boolean, confidenceScore: number, reasons: Array, severity: string }
   */
  static evaluateCrashConfidence(telemetryData, sensitivity = 'medium') {
    const {
      accelG = 1.0,
      gyroRadSec = 0.0,
      speedBeforeKmh = 0.0,
      speedAfterKmh = 0.0,
      pitchDeg = 0.0,
      rollDeg = 0.0,
      isRiderImmobile = false,
    } = telemetryData;

    let scoreWeights = {
      accelSpike: 0,
      gyroRotation: 0,
      speedDeceleration: 0,
      orientationShift: 0,
      postImpactImmobility: 0,
    };

    const reasons = [];

    // Threshold adjusters based on sensitivity
    let accelThresholdG = sensitivity === 'high' ? 3.0 : sensitivity === 'low' ? 4.5 : 3.8;
    let gyroThresholdRad = sensitivity === 'high' ? 3.0 : sensitivity === 'low' ? 5.0 : 4.0;

    // 1. Accelerometer Vertical & Vector Spike Check
    if (accelG >= accelThresholdG) {
      const gFactor = Math.min((accelG - accelThresholdG) / 3.0, 1.0);
      scoreWeights.accelSpike = 0.35 + gFactor * 0.15; // Max 0.50
      reasons.push(`High G-force impact detected (${accelG.toFixed(1)}G)`);
    } else if (accelG >= 2.2) {
      // Mild bump or speed breaker
      scoreWeights.accelSpike = 0.15;
    }

    // 2. Gyroscope Angular Velocity Check (Phone/Bike flipping/spinning)
    if (gyroRadSec >= gyroThresholdRad) {
      scoreWeights.gyroRotation = 0.25;
      reasons.push(`Sudden high rotational velocity (${gyroRadSec.toFixed(1)} rad/s)`);
    } else if (gyroRadSec >= 2.0) {
      scoreWeights.gyroRotation = 0.10;
    }

    // 3. GPS Speed Drop (Rapid Deceleration)
    const speedDrop = Math.max(0, speedBeforeKmh - speedAfterKmh);
    if (speedBeforeKmh > 15 && speedAfterKmh < 5) {
      scoreWeights.speedDeceleration = 0.25;
      reasons.push(`Rapid motorcycle deceleration (${speedBeforeKmh.toFixed(0)} -> ${speedAfterKmh.toFixed(0)} km/h)`);
    } else if (speedDrop > 20) {
      scoreWeights.speedDeceleration = 0.15;
    }

    // 4. Orientation Tilt Check (Bike fallen sideways or rider thrown)
    const maxTilt = Math.max(Math.abs(pitchDeg), Math.abs(rollDeg));
    if (maxTilt > 45) {
      scoreWeights.orientationShift = 0.15;
      reasons.push(`Significant phone orientation tilt (${maxTilt.toFixed(0)}°)`);
    }

    // 5. Post-Impact Immobility Check
    if (isRiderImmobile && accelG >= accelThresholdG) {
      scoreWeights.postImpactImmobility = 0.15;
      reasons.push('Post-impact rider immobility detected');
    }

    // Total raw confidence score
    let totalScore =
      scoreWeights.accelSpike +
      scoreWeights.gyroRotation +
      scoreWeights.speedDeceleration +
      scoreWeights.orientationShift +
      scoreWeights.postImpactImmobility;

    // Filter Out False Positives:
    // - Case A: Isolated G-spike while stationary or walking (Speed < 5 km/h, no rotational spin) -> zero out
    if (speedBeforeKmh < 6 && gyroRadSec < 2.0) {
      totalScore *= 0.2; // Likely user dropped phone or walked
    }

    // - Case B: Road Speed Breaker (Moderate accel spike, zero rotation, controlled speed drop)
    if (gyroRadSec < 1.5 && Math.abs(pitchDeg) < 20 && Math.abs(rollDeg) < 20 && speedBeforeKmh < 35) {
      totalScore *= 0.4;
    }

    // Cap confidence score between 0 and 100%
    const confidenceScorePercent = Math.min(Math.round(totalScore * 100), 100);
    const isCrashDetected = confidenceScorePercent >= 90;

    let severity = 'LOW';
    if (confidenceScorePercent >= 90) severity = 'CRITICAL';
    else if (confidenceScorePercent >= 75) severity = 'HIGH';
    else if (confidenceScorePercent >= 50) severity = 'MEDIUM';

    return {
      isCrashDetected,
      confidenceScore: confidenceScorePercent,
      severity,
      reasons,
      breakdown: scoreWeights,
    };
  }
}

module.exports = SensorFusionService;
