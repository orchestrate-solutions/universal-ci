pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(5, 3), 8);
        assert_eq!(add(0, 0), 0);
        assert_eq!(add(-2, -3), -5);
    }
}
