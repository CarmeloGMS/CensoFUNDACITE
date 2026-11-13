from rest_framework.permissions import BasePermission


def user_role(user):
    if user.is_superuser:
        return "administrador"
    return user.groups.order_by("name").values_list("name", flat=True).first()


class IsConsejoReader(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)

    def has_object_permission(self, request, view, obj):
        role = user_role(request.user)
        return role in {"administrador", "supervisor"} or obj.registrado_por_id == request.user.id


class IsAdministrator(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated and user_role(request.user) == "administrador")
