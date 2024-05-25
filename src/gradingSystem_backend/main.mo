import Debug "mo:base/Debug";

actor {
    // A function to calculate the grade based on the score
    public func calculateGrade(score : Nat, name : Text) : async Text {
        Debug.print("Eniola Hannah");

        var grade : Text = "F";

        if (score >= 80 and score <= 100) {
            grade := "A1 ~ Excellent";
        } else if (score >= 70 and score <= 79) {
            grade := "B2 ~ Very Good";
        } else if (score >= 65 and score <= 69) {
            grade := "B3 ~ Good";
        } else if (score >= 60 and score <= 64) {
            grade := "C4 ~ Distinctive";
        } else if (score >= 50 and score <= 59) {
            grade := "C5 ~ Credit";
        } else if (score >= 45 and score <= 49) {
            grade := "D ~ Pass";
        } else if (score >= 40 and score <= 44) {
            grade := "E8 ~ Pass";
        } else if (score >= 0 and score <= 39) {
            grade := "F9 ~ Fail";
        } else {
            return "Not a valid score";
        };

        return "Hey " # name # ", Your grade is : " # grade;
    };
};
