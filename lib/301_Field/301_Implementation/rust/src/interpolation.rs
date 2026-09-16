#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum InterpolationScheme {
    NearestNeighbor,
    Linear,
    Bilinear,
    Trilinear,
}

impl InterpolationScheme {
    /// 1D Linear Interpolation
    pub fn lerp(v0: f64, v1: f64, t: f64) -> f64 {
        v0 + t * (v1 - v0)
    }

    /// 2D Bilinear Interpolation
    /// v00 = f(0, 0), v10 = f(1, 0), v01 = f(0, 1), v11 = f(1, 1)
    pub fn bilerp(v00: f64, v10: f64, v01: f64, v11: f64, tx: f64, ty: f64) -> f64 {
        let bottom = Self::lerp(v00, v10, tx);
        let top = Self::lerp(v01, v11, tx);
        Self::lerp(bottom, top, ty)
    }

    /// 3D Trilinear Interpolation
    pub fn trilerp(
        c000: f64,
        c100: f64,
        c010: f64,
        c110: f64,
        c001: f64,
        c101: f64,
        c011: f64,
        c111: f64,
        tx: f64,
        ty: f64,
        tz: f64,
    ) -> f64 {
        let z0 = Self::bilerp(c000, c100, c010, c110, tx, ty);
        let z1 = Self::bilerp(c001, c101, c011, c111, tx, ty);
        Self::lerp(z0, z1, tz)
    }
}
