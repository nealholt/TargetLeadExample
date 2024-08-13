extends Node3D

@export var bullet: PackedScene # What sort of bullet to fire
var projectile_speed : float
@export var fire_rate:= 2.0 # Shots per second
@export var target : Node3D
@export var lead_target: bool = false
@export var bullet_drop := 0.0
var elevation_angle : float = 0.0 # For compensating for bullet drop

@onready var timer: Timer = $Timer
@onready var bullet_spawn_loc: Node3D = $blasterF2/BulletSpawnLoc
@onready var muzzle_flash: GPUParticles3D = $blasterF2/BulletSpawnLoc/MuzzleFlash

var can_shoot: bool = false # For bullet firing rate

func _ready():
	timer.start(1.0/fire_rate)
	# Create a bullet just to ask it for its speed
	var b = bullet.instantiate()
	projectile_speed = b.speed
	b.queue_free()


func _physics_process(_delta: float) -> void:
	var target_pos := target.global_position
	if lead_target:
		target_pos = get_intercept(
			bullet_spawn_loc.global_position,
			projectile_speed * cos(elevation_angle), #CHANGED
			target.global_position,
			target.velocity)
	look_at(target_pos, Vector3.UP)
	#Account for bullet drop # ADDED
	if bullet_drop != 0.0: # ADDED
		#print('') #ADDED
		#print(target.velocity.length()) #ADDED
		#print(projectile_speed) #ADDED
		#print(projectile_speed * cos(angle_to_target)) #ADDED
		set_firing_angle() #ADDED
		#print(rad_to_deg(angle_to_target)) #ADDED
		rotate_x(elevation_angle) #ADDED
	# Shoot automatically, as often as you can
	#if Input.is_action_pressed("ui_accept"):
	shoot()


# Returns true if successful, useful for animations and sounds
func shoot() -> void:
	if can_shoot:
		muzzle_flash.emitting = true
		can_shoot = false
		# Create and fire the bullet
		var b = bullet.instantiate()
		# Add bullet to root node otherwise queue free
		# on shooter will queue free the bullet
		get_tree().get_root().add_child(b)
		# Fire from the position and orientation of the gun
		b.transform = bullet_spawn_loc.global_transform
		b.origin = bullet_spawn_loc.global_position
		b.set_movement_vector()
		if "gravity" in b:
			b.gravity = bullet_drop
		# Reset the timer
		timer.start(1.0/fire_rate)


func _on_timer_timeout() -> void:
	can_shoot = true


func set_firing_angle(): #ADDED
	# Avoid divide by zero
	if bullet_drop == 0.0:
		elevation_angle = 0.0
		return
	
	# The following code is based on this:
	# https://www.youtube.com/watch?v=bqYtNrhdDAY
	# and the simpler, equal height, case is based
	# on this:
	# https://physics.stackexchange.com/questions/249321/angle-required-to-hit-the-target-in-projectile-motion
	
	# Get the height of the gun relative to the target.
	# I don't know why I need -abs here, but all the
	# tutorial videos I found had the shooter above
	# the target and if the shooter is below and you
	# don't use -abs, then the calculation doesn't work.
	var h:float = -abs(bullet_spawn_loc.global_position.y - target.global_position.y)
	
	#TODO Whole other approach. Source:
	# https://en.wikipedia.org/wiki/Projectile_motion#Angle_%CE%B8_required_to_hit_coordinate_(x,_y)
	# Initial horizontal velocity
	var v0:float = projectile_speed
	# Horizontal distance, x
	var tempx:float = bullet_spawn_loc.global_position.x - target.global_position.x
	var tempz:float = bullet_spawn_loc.global_position.z - target.global_position.z
	var x:float = sqrt(tempx**2 + tempz**2)
	# Vertical distance y
	var y:float = bullet_spawn_loc.global_position.y - target.global_position.y
	# Gravity
	var g:float = -bullet_drop #Negative needed
	var angle1:float = atan( (v0**2 + sqrt(v0**4 - g*(g*x**2+2*y*v0**2))) / (g*x) )
	var angle2:float = atan( (v0**2 - sqrt(v0**4 - g*(g*x**2+2*y*v0**2))) / (g*x) )
	print(PI/2 - angle1)
	#print(angle1)
	print(angle2)
	elevation_angle = PI/2 - angle1
	#elevation_angle = angle1
	#elevation_angle = angle2
	
	# If there is no difference in height, then do a
	# simpler calculation and avoid another divide by zero
	# Use   angle = arctan(v0**2/(g*x))
	#print(h)
	#if true: # h == 0 TODO
		## Initial horizontal velocity
		#var v0:float = projectile_speed * cos(elevation_angle)
		## Gravity
		#var g:float = -bullet_drop #Negative needed
		## Horizontal distance, x
		#var tempx:float = bullet_spawn_loc.global_position.x - target.global_position.x
		#var tempz:float = bullet_spawn_loc.global_position.z - target.global_position.z
		#var x:float = sqrt(tempx**2 + tempz**2)
		#elevation_angle = PI/2 - atan( (v0**2) / (g*x) )
	#else:
		## Initial velocity
		#var v0:float = projectile_speed
		## Gravity
		#var g:float = bullet_drop #No negative
		## Horizontal distance, x
		#var tempx:float = bullet_spawn_loc.global_position.x - target.global_position.x
		#var tempz:float = bullet_spawn_loc.global_position.z - target.global_position.z
		#var x = sqrt(tempx**2 + tempz**2)
		## Various terms for organzation
		#var phi:float = atan(x/h)
		#var numerator:float = (g*x**2) / v0**2 - h
		#var denominator:float = sqrt(h**2 + x**2)
		#var answer_temp = acos( numerator/denominator )
		#elevation_angle = (answer_temp + phi) / 2


# Original source/inspiration:
# https://www.gamedev.net/forums/topic.asp?topic_id=401165
# (which has at least one typo, no negative in front of b
# in the quadratic equation)
# Positions and vectors are all either a tuple (x,y)
# in 2-dimensions or a triple (x,y,z) in 3-dimensions.
# Positions and vectors will be represented with
# capital letters.
# There's no difference between a position and a vector
# when it comes down to the calculation, I'm just
# distinguishing them to be pedantic.
# dot(A,B) represents the dot product of A and B.
# Let
# P1 = shooter position
# P2 = target position
# speed = projectile speed, a scalar
# V = target velocity
# then coefficients of a quadratic with time as the variable are:
# a = speed^2 - dot(V,V)
# b = -2*dot(V,P2-P1)
# c = -dot(P2-P1,P2-P1)
# and the position in space where the projectile can hit the
# target, if fired toward the position at t=0 is
# intercept = P2 + ((-b+sqrt(b^2-4*a*c))/(2*a)) * V
# but why?
# Instead of ((b+sqrt(b^2-4*a*c))/(2*a)), let's write t:
# intercept = P2 + t*V
# t is a scalar representing time. Therefore P2 + t*V is
# the position of the target at time t. The current
# position is P2 and it moves at velocity V so it will be
# at P2+t*V after t seconds.
# We want to find the value of t that makes the distance
# between the shooter P1 and where the target will be
# P2+t*V equal t*speed which is how far our projectile
# can travel in t seconds.
# So we set the magnitude of the vector P2+t*V - P1
# equal to t*speed:
# sqrt(dot(P2+t*V - P1, P2+t*V - P1)) = t*speed
# And then we solve for t. Step 1: square both sides.
# dot(P2+t*V-P1, P2+t*V-P1) = t^2*speed^2
# To pull t out of that dot product we need to apply the
# Bilinear property of the dot product three times over:
# https://en.wikipedia.org/wiki/Dot_product#Properties
# The property states:
# dot(A,rB+C) = r*dot(A,B)+dot(A,C)
# where A,B,C are vectors and r is a scalar.
# Before we apply the bilinear property it might help to
# rearrange our dot product to better match the form
# dot(P2+t*V-P1,P2+t*V-P1) =>
# dot(P2+t*V-P1,t*V+P2-P1)
# dot(     A   ,r*B+  C  )
# First application:
# dot(P2+t*V-P1,t*V+P2-P1) =>
# t*dot(P2+t*V-P1,V) + dot(P2+t*V-P1,P2-P1)
# We need to again apply the property on both sides, but
# let's rearrange first to better match the form of the property
# t*dot(P2+t*V-P1,V) + dot(P2+t*V-P1,P2-P1) =>
# t*dot(V,t*V+P2-P1) + dot(P2-P1,t*V+P2-P1)
#   dot(A,r*B+  C  ) + dot(  A  ,r*B+  C  )
# second and third application of the property yields:
# t*dot(V,t*V+P2-P1) + dot(P2-P1,t*V+P2-P1) =>
# t^2*dot(V,V)+t*dot(V,P2-P1) + t*dot(V,P2-P1)+dot(P2-P1,P2-P1) =>
# combining like terms
# t^2*dot(V,V) +2*t*dot(V,P2-P1)+ dot(P2-P1,P2-P1)
# Whew!
# Now remember this was all equal to t^2*speed^2 and our
# goal was to solve for t.
# t^2*dot(V,V) +2*t*dot(V,P2-P1)+ dot(P2-P1,P2-P1) = t^2*speed^2
# Subtract all the left side terms from both sides
# to get the following:
# t^2*(speed^2-dot(V,V)) -2*t*dot(V,P2-P1)- dot(P2-P1,P2-P1) = 0
# (You might reasonably ask, why not just subtract t^2*speed^2
# from both sides, wouldn't that be easier? Yes, it would, but
# we get nicer canceling of negative signs when we plug into
# the quadratic formula if we do it this way. )
# This is a quadratic!
# a*t^2 + b*t + c = 0
# with
# a = speed^2-dot(V,V)
# b = -2*dot(V,P2-P1)
# c = -dot(P2-P1,P2-P1)
# We can use the quadratic formula to solve for t
# t = ((-b+-sqrt(b^2-4*a*c))/(2*a))
# And that concludes our explanation of why our intercept point is
# intercept = P2 + t*V
# written as
# intercept = P2 + ((-b+sqrt(b^2-4*a*c))/(2*a)) * V
# (Note, -b was just b in the webpage above, which
# is a mistake.)
# When can it go wrong and what to do about it?
# What about when a = 0 ? (aka speed^2-dot(V,V)=0 )
# Or when b^2-4*a*c is negative?
# This can occur when speed of the target equals or
# surpasses speed of the projectile, in which case
# the projectile never reaches the target. No solution.
# I check for this explicitly in my code and simply
# use t=0 when that is the case. It's no use shooting
# the target anyway, so what's the point of leading it?
	#if bullet_speed <= target_velocity.length():
		#return target_pos
	#else:
		#return target_pos+largest_root_of_quadratic(a,b,c)*target_velocity
# Another problem: The quadratic formula has a +/-
# and we're only calculating the +
# What about (-b-sqrt(b^2-4*a*c))/(2*a) ?
# Our explainer (from website above) claims that this is
# never the desired value of t, and now our negative signs
# come in handy to see why! Dot producting a vector with
# itself always yields a positive number (just try it)
# and therefore c is always negative and a is positive
# so long as projectile speed is greater than target speed.
# ...actually I lost track of the rest of the explanation
# but it's certainly easy to see how the minus calculation
# will be less than the plus calculation, or even negative,
# which is not desirable unless we can travel backward in time!
# Further concerns:
# What if my shooter is also moving and the bullets inherit
# the shooter's velocity (which is reasonable because that's
# how actual physics work)?
# You should be able to simply use V = V_target - V_shooter
# instead of the V_target used above and it should work fine.
# What if it still doesn't work and I can't figure out why?
# 1. Check for typos, copy-paste errors, missing negative
# signs, mismatched parentheses.
# 2. Make sure you're calculating based on positions and
# vectors that you're actually using. I calculated position
# of shooter based on the center of the model, but then I
# spawned the bullets from the tip of the gun barrel which
# was not the same location at all.
# Here's my Godot script solution:
# You WILL notice missing negative signs because I
# cancelled them. For instance:
# b = -2*dot(V,P2-P1)
# c = -dot(P2-P1,P2-P1)
# t = ((-b+sqrt(b^2-4*a*c))/(2*a))
# becomes
# b = 2*dot(V,P2-P1)
# c = dot(P2-P1,P2-P1)
# t = ((b+sqrt(b^2+4*a*c))/(2*a))
func get_intercept(shooter_pos:Vector3,
					bullet_speed:float,
					target_position:Vector3,
					target_velocity:Vector3) -> Vector3:
	var a:float = bullet_speed*bullet_speed - target_velocity.dot(target_velocity)
	var b:float = 2*target_velocity.dot(target_position-shooter_pos)
	var c:float = (target_position-shooter_pos).dot(target_position-shooter_pos)
	# Protect against divide by zero and/or imaginary results
	# which occur when bullet speed is slower than target speed
	var time:float = 0.0
	if bullet_speed > target_velocity.length():
		time = (b+sqrt(b*b+4*a*c)) / (2*a)
	return target_position+time*target_velocity
