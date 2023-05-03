/* Removes features with no counts across all samples. */

SELECT featureID, sampleID, value
    FROM assay
    WHERE featureID NOT IN (
        SELECT featureID
        FROM assay
        GROUP BY featureID
        HAVING SUM(value) = 0
    );