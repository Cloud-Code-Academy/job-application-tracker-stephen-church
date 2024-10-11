public with sharing class FederalWithholdingHelper {

    public static Decimal getAmountToTaxInTaxBracket (Decimal salary, Decimal taxBracketStart, Decimal taxBracketEnd) {

        // taxBracketEnd isn't checked because the upper tax brackets don't have a limit and could be null
        if (salary == null || taxBracketStart == null) {
            Utility.throwIllegalArgumentException('Null arguments were passed into the method');
        }
        
        Decimal amountToTax = null;
        // If salary is less than the start of the tax bracket, no tax is due
        if (salary < taxBracketStart) {
            amountToTax = 0;
        // If salary is within the tax bracket but not greater than the end (or it has no end), tax the amount over the start in the range
        } else if (salary >= taxBracketStart && (salary < taxBracketEnd || taxBracketEnd == null)) {
            amountToTax = (salary - taxBracketStart);
        // If salary is greater than or equal to the tax bracket end, the whole amount in the tax bracket range needs to be taxed
        } else if (salary >= taxBracketEnd) {
            amountToTax = (taxBracketEnd - taxBracketStart);
        }
        return amountToTax;
    }

    public static Decimal calculateTaxesDue (Decimal amountToTax, Decimal rateToTax) {

        if (amountToTax == null || rateToTax == null) {
            Utility.throwIllegalArgumentException('Null arguments were passed into the method');
        }

        Decimal taxDue = (amountToTax / 100) * rateToTax;
        return taxDue;
    }
}