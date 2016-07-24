#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: emi_cal.pl
#
#        USAGE: ./emi_cal.pl  
#
#  DESCRIPTION: The script would calculate emi and it even tells if its profitable
#  				to buy the house. What would be the total profit or loss.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Daniel Raj ()
#      VERSION: 1.0
#      CREATED: 07/24/2016 11:02:21 AM
#     REVISION: ---
#===============================================================================


my $max_yrly_intr = 200000;

&main;



sub main (){

	print "Loan Amt in Lac(eg: 25):";
	$loan_amt=<>;
	chomp($loan_amt);
	$loan_amt = $loan_amt * 100000 ; # convert to lacs
	print "ROI(eg: 10.25):";
	$roi=<>;
	chomp($roi);
	print "Tenure in yrs(eg: 20):";
	$yrs=<>;
	chomp($yrs);
	print "let_out_for_rent(yes/no):";
	$let_out_for_rent=<>;
	chomp($let_out_for_rent);

	if ($let_out_for_rent =~ /yes/i) {
		$let_out_for_rent = 1;
		print "Enter Expected Monthly Rent You Might Get(eg: 6000):";
		$monthly_rent=<>;
		chomp($monthly_rent);
	}
	else{
		$monthly_rent=0;
		$let_out_for_rent = 0;
		print "Enter Estimated Rent Amount You Have To Pay(eg: 6000):";
		$est_rent=<>;
		chomp($est_rent);
	}

	print "Tax Bracket in %(eg: 10/20/30):";
	$tax_bracket=<>;
	chomp($tax_bracket);
	$tax_bracket = $tax_bracket/100; #30%

	print "Existing deductions under 80C/D:";
	$existing_80c=<>;
	chomp($existing_80c);

	if ( $existing_80c < 150000) {
	  $remaining_80c = 150000 - $existing_80c;
	}


	$num_months = $yrs * 12;
	$mon_roi = sprintf" %.5f",(($roi/12)*.01) ;			# monthly rate of intrst
	print "mon_roi: $mon_roi\n";

	$A1=$loan_amt*$mon_roi;
	$A2=1+$mon_roi;
	$A3=&powerof($A2,$num_months); # $A2 ^ $num_months
	$A3=sprintf" %.5f",$A3;
	$A4= $A3 -1;

	$emi = int (($A1 * $A3) / $A4);

	$total_amt = $emi * $num_months;
	$intrst=$total_amt-$loan_amt;


	print "\n**********************************************************************\n";
	print "Your EMI: ₹ $emi\n" ;
	print "For LoanAmt: ₹",$loan_amt/100000," Lac\n" ;
	print "For A Period of: $yrs Year's\n" ;
	print "@ ROI: ",$roi,"  Monthly_ROI: s",$mon_roi,"\n\n";

	print "TotalInterest: ₹", $intrst/100000," Lac\n";
	print "TotalAmountToPay(LoanAmt+Interest): ₹",($loan_amt+$intrst)/100000," Lac\n\n";

	($let_out_for_rent)?print "Expected Monthly Rent: ₹$monthly_rent\n":print "Estimated Monthly Rent: ₹$est_rent\n";
	print "Esisting 80C/D deductions: ₹ $existing_80c\n";
#	print "\n**********************************************************************\n";
	$yrly_statement = 1;
	$monthly_statement = 0;
	&yearly_split;
	&return_of_investment;
}

sub powerof () {

	$a = shift;
	$n = shift;
	$a1= $a;

	for ($i=1; $i<$n; $i++){
		$a1=$a1*$a;
	}
	return $a1;	
}


sub yearly_split (){

	print "\n**********************************************************************\n";
	print "EMI's                                            \n\n";
	print "Year  ,IntrstPaid,PrincipalPaid,LoanAmtRemaining,tax_exempt => [ On Intr + On Prncp - On Rent Paid ] \n";

	$loan_amt_rmng = $loan_amt;
#	$monthly_rent = 7000;
	$total_tax_exempt =0;

	for ($i=1;$i<=$yrs;$i++){

		$yrly_intr = 0;
		$yrly_prncp = 0;
		$act_yrly_intr = 0;

		for ($mon=1;$mon<=12;$mon++){

			$intr_paid = int ($mon_roi * $loan_amt_rmng);
			$prncp_paid = int($emi - $intr_paid);
			$loan_amt_rmng = $loan_amt_rmng - $prncp_paid;

			if ($monthly_statement){
				print "Month:",$i*$mon,",$intr_paid,$prncp_paid,$loan_amt_rmng\n";
			}
			$yrly_intr = $yrly_intr + $intr_paid;
			$yrly_prncp = $yrly_prncp + $prncp_paid;
		}

		if ($yrly_statement){
			$yrly_rent =$monthly_rent*12;

			$act_yrly_intr = $yrly_intr ;
			if ($yrly_intr > $max_yrly_intr) {
				$act_yrly_intr = $yrly_intr ;
				$yrly_intr = $max_yrly_intr ;	
			}

			if ($yrly_prncp > $remaining_80c) {
				$act_yrly_prncp = $yrly_prncp ;
				$tax_yrly_prncp = $remaining_80c ;	
			}

			$tax_exempt_intr = ($yrly_intr * $tax_bracket) ;
			$tax_exempt_prncp = ($tax_yrly_prncp * $tax_bracket) ;
			$tax_on_rent = ($yrly_rent*.7*$tax_bracket);
			if ($tax_exempt > 75000) { $tax_exempt = 75000;}

			$tax_exempt = $tax_exempt_intr + $tax_exempt_prncp - $tax_on_rent ;
#			$tax_exempt = ($yrly_intr * $tax_bracket) + ($tax_yrly_prncp * $tax_bracket) - ($yrly_rent*.7*$tax_bracket);
			$total_tax_on_rent += $tax_on_rent ;
			$total_intr_tax_exempt = $total_intr_tax_exempt + $tax_exempt_intr ;
			$total_prncp_tax_exempt = $total_prncp_tax_exempt + $tax_exempt_prncp ;
			$total_tax_exempt = $total_tax_exempt + $tax_exempt;
			$total_rent_for_loan_prd = $total_rent + $yrly_rent;
#			print "Year:$i,$yrly_intr,$yrly_prncp,$loan_amt_rmng,$tax_exempt,\n";
			print "Year:$i,     $act_yrly_intr,      $yrly_prncp,      $loan_amt_rmng,   $tax_exempt => [$tax_exempt_intr + $tax_exempt_prncp - $tax_on_rent]\n";

		}
	}
 	print "\n**********************************************************************\n";

}

sub return_of_investment () {


	print "Verdict                                          \n\n";

	$rent_aft_loan_prd=($monthly_rent*2*12*(30-$yrs)); # assuming rent will be double and you will get rent for 30yrs atleast
	$tax_for_rest_of_yrs=$rent_aft_loan_prd*$tax_bracket;
	$roi_dur_loan_prd 	= int ($total_tax_exempt+$total_rent_for_loan_prd);
	$roi_aftr_loan_prd		= int ($rent_aft_loan_prd-$tax_for_rest_of_yrs);
	$total_return_of_investment = $roi_dur_loan_prd + $roi_aftr_loan_prd;

	if ($let_out_for_rent){
		if ($total_return_of_investment < $total_amt){

			print "It's a loss don't buy this house\n";
			print "Loss Amount:",int (($total_amt-$total_return_of_investment)/100000),"Lac's\n";
		}
		else {
			print "Good choice to buy this property\n";
			print "Your profit Amount:",int(($total_return_of_investment-$total_amt)/100000),"\n";
		}
	}
	else{


		#rent for first 15yrs
		$rent_saved_1 = $est_rent * 12 * 15 ; #12 months * 15 yrs

		#rent for next 15yrs
		$rent_saved_2 = $est_rent * 2 * 12 * 15 ; # rent is doubled 12 months * yrs

		$total_rent_saved = $rent_saved_2 + $rent_saved_2 + $total_tax_exempt;

		print "Total Rent Saved: $total_rent_saved(rent+tax_exemption)\n";

		if ($total_rent_saved < $total_amt){

			print "It's a loss don't buy this house ";
			print "Loss Amount:",int (($total_amt-$total_rent_saved)/100000),"Lac's\n";
		}
		else {
			print "Good choice to buy this property ";
			print "Your profit Amount:",int (($total_rent_saved-$total_amt)/100000),"Lac's\n";
		}

	}

	print "\n**********************************************************************\n";
	print "Why I Think So\n\n";

	print "Total Amount Paid (LoanAmt+Interest):". sprintf " %.2f Lac's \n", ($loan_amt+$intrst)/100000;
	print "Total Return of Investment in 30yrs\n(ie Rent Recieved/Saved+Tax Exempt):". sprintf " %.2f Lac's \n", ($total_return_of_investment/100000);
	print "Tax Exemption on Interest     :" . sprintf " %.2f Lac's \n", ($total_intr_tax_exempt/100000)  ;
	print "Tax Exemption on Principal    :" . sprintf " %.2f Lac's \n", ($total_prncp_tax_exempt/100000) ;


	if ($let_out_for_rent) {
		print "Rent Amount During Loan Period:" . sprintf " %.2f Lac's \n", ($total_rent_for_loan_prd/100000);
		print "Rent Amount After  Loan Period:" . sprintf " %.2f Lac's \n", ($rent_aft_loan_prd/100000)      ;
		print "Tax On Rent During Loan Period: (-)". sprintf " %.2f Lac's \n", ($total_tax_on_rent/100000)    ;	
		print "Tax On Rent After  Loan Period: (-)". sprintf " %.2f Lac's \n", ($tax_for_rest_of_yrs/100000)    ;

		print "\nAssumption: rent will be doubled only after the loan period and\n you will get rent for atleast 30yrs\n";
	}
	else {
		print "\nAssumption: rent will be doubled only after 15 years and\n you will get rent for alteast 30yrs\n";
	}


	print "\n**********************************************************************\n";



}
